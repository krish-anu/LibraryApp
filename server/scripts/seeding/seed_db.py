from pathlib import Path
import sys


SERVER_ROOT = Path(__file__).resolve().parents[2]
if str(SERVER_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVER_ROOT))

from app.db import SessionLocal, engine
from app.models.author import Author
from app.models.base import Base
from app.models.book import Book
from app.models.category import Category
from app.models.loan import Loan
from app.models.users import User
from scripts.seeding.data import (
    authors_data,
    books_data,
    categories_data,
    loans_data,
    users_data,
)


TABLES_TO_RESET = (
    "interactions",
    "loans",
    "book_author",
    "books",
    "authors",
    "categories",
    "users",
)


def reset_tables() -> None:
    print("Dropping and recreating tables (using CASCADE for dependents)...")
    with engine.begin() as conn:
        for table_name in TABLES_TO_RESET:
            conn.exec_driver_sql(f"DROP TABLE IF EXISTS {table_name} CASCADE")
    Base.metadata.create_all(bind=engine)


def seed_categories(db) -> dict[str, str]:
    print(f"Seeding {len(categories_data)} categories...")
    name_to_id = {}
    for category in categories_data:
        category_id = category.get("id")
        name = category.get("name")
        image_url = category.get("image_url")
        if category_id and name:
            db.add(Category(id=category_id, name=name, image_url=image_url))
            name_to_id[name.strip().lower()] = category_id
    return name_to_id


def seed_authors(db) -> dict[str, str]:
    print(f"Seeding {len(authors_data)} authors...")
    author_name_to_id = {}
    for author in authors_data:
        author_id = author.get("id")
        first_name = author.get("first_name")
        last_name = author.get("last_name")
        if author_id and first_name is not None:
            db.add(Author(id=author_id, first_name=first_name, last_name=last_name))
            full_name = f"{first_name} {last_name}".strip().lower()
            author_name_to_id[full_name] = author_id
    return author_name_to_id


def normalize_book_data(book_data, name_to_id, author_name_to_id) -> dict:
    book = dict(book_data)
    if "publicationYear" in book:
        book["publication_year"] = book.pop("publicationYear")
    if "copiesOwned" in book:
        book["copies_owned"] = book.pop("copiesOwned")

    if not book.get("category_id") and book.get("category"):
        category_name = str(book.pop("category")).strip().lower()
        category_id = name_to_id.get(category_name)
        if category_id is None:
            category_id = category_name.replace(" ", "-").replace("/", "-")
            name_to_id[category_name] = category_id
        book["category_id"] = category_id

    if not book.get("author_id") and book.get("author"):
        author_name = str(book.pop("author")).strip().lower()
        author_id = author_name_to_id.get(author_name)
        if author_id is None:
            parts = author_name.split()
            first_name = " ".join(parts[:-1]) if len(parts) > 1 else parts[0]
            last_name = parts[-1] if len(parts) > 1 else ""
            author_id = str(len(author_name_to_id) + 1)
            author_name_to_id[author_name] = author_id
            book["_new_author"] = Author(
                id=author_id,
                first_name=first_name,
                last_name=last_name,
            )
        book["author_id"] = author_id

    return book


def seed_books(db, name_to_id, author_name_to_id) -> None:
    print(f"Seeding {len(books_data)} books...")
    for book_data in books_data:
        book = normalize_book_data(book_data, name_to_id, author_name_to_id)
        new_author = book.pop("_new_author", None)
        if new_author is not None:
            db.add(new_author)
        db.add(Book(**book))


def seed_users(db) -> None:
    print(f"Seeding {len(users_data)} users...")
    for user_data in users_data:
        db.add(
            User(
                id=user_data.get("id"),
                member_id=user_data.get("member_id"),
                name=user_data.get("name"),
                email=user_data.get("email"),
                password=None,
            )
        )


def seed_loans(db) -> None:
    print(f"Seeding {len(loans_data)} loans...")
    for loan_data in loans_data:
        db.add(Loan(**loan_data))


def seed() -> None:
    reset_tables()
    db = SessionLocal()
    try:
        name_to_id = seed_categories(db)
        author_name_to_id = seed_authors(db)
        db.flush()
        seed_books(db, name_to_id, author_name_to_id)
        seed_users(db)
        seed_loans(db)
        db.commit()
        print("Seeded successfully!")
    except Exception as exc:
        print(f"Error seeding data: {exc}")
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    seed()
