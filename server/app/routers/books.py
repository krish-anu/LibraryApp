from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text, func
from typing import List, cast
from datetime import datetime, timedelta, timezone

from ..dependencies import get_db, verify_access_token
from ..models import book as book_model
from ..models import category as category_model
from ..models.interactions import Interaction
from ..pydantic_schemas import book as book_schema

router = APIRouter(
    prefix="/books", tags=["books"], dependencies=[Depends(verify_access_token)]
)


def _book_to_response(book_obj: book_model.Book) -> book_schema.Book:
    return book_schema.Book(
        id=str(book_obj.id),
        title=str(book_obj.title or ""),
        author=str(book_obj.author or ""),
        category=str(book_obj.category or ""),
        description=str(book_obj.description or ""),
        rating=(
            float(cast(float, book_obj.rating)) if book_obj.rating is not None else 0.0
        ),
        publication_year=(
            int(cast(int, book_obj.publication_year))
            if book_obj.publication_year is not None
            else 0
        ),
        copies_owned=(
            int(cast(int, book_obj.copies_owned))
            if book_obj.copies_owned is not None
            else 0
        ),
        image=str(book_obj.image or ""),
        language=str(book_obj.language or "English"),
        pages=(int(cast(int, book_obj.pages)) if book_obj.pages is not None else 200),
        rating_count=(
            int(cast(int, book_obj.rating_count))
            if book_obj.rating_count is not None
            else 0
        ),
    )


@router.get("", response_model=List[book_schema.Book])
def get_books(db: Session = Depends(get_db)):
    books = db.query(book_model.Book).all()
    return [_book_to_response(b) for b in books]


@router.post("", response_model=book_schema.Book, status_code=201)
def create_book(book_data: book_schema.BookCreate, db: Session = Depends(get_db)):
    existing_category = (
        db.query(category_model.Category)
        .filter(category_model.Category.name == book_data.category)
        .first()
    )

    if not existing_category:
        existing_category = category_model.Category(
            id=f"cat_{book_data.category.lower().replace(' ', '_')}",
            name=book_data.category,
        )
        db.add(existing_category)
        db.commit()
        db.refresh(existing_category)

    new_book = book_model.Book(
        id=f"book_{datetime.now().timestamp()}",
        title=book_data.title,
        author_id=None,
        category_id=existing_category.id,
        description=book_data.description,
        rating=book_data.rating,
        publication_year=book_data.publication_year,
        copies_owned=book_data.copies_owned,
        image=book_data.image,
        language=book_data.language,
        pages=book_data.pages,
        rating_count=book_data.rating_count,
    )
    db.add(new_book)
    db.commit()
    db.refresh(new_book)
    return _book_to_response(new_book)


@router.get("/{book_id}", response_model=book_schema.Book)
def get_book(book_id: str, db: Session = Depends(get_db)):
    book_obj = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")
    return _book_to_response(book_obj)


@router.put("/{book_id}", response_model=book_schema.Book)
def update_book(
    book_id: str, book_data: book_schema.BookCreate, db: Session = Depends(get_db)
):
    book_obj = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")

    if book_data.category != (book_obj.category or ""):
        existing_category = (
            db.query(category_model.Category)
            .filter(category_model.Category.name == book_data.category)
            .first()
        )
        if not existing_category:
            existing_category = category_model.Category(
                id=f"cat_{book_data.category.lower().replace(' ', '_')}",
                name=book_data.category,
            )
            db.add(existing_category)
            db.commit()
            db.refresh(existing_category)
        book_obj.category_id = existing_category.id

    book_obj.title = book_data.title
    book_obj.description = book_data.description
    book_obj.rating = book_data.rating
    book_obj.publication_year = book_data.publication_year
    book_obj.copies_owned = book_data.copies_owned
    book_obj.image = book_data.image
    book_obj.language = book_data.language
    book_obj.pages = book_data.pages
    book_obj.rating_count = book_data.rating_count

    db.commit()
    db.refresh(book_obj)
    return _book_to_response(book_obj)


@router.delete("/{book_id}", status_code=204)
def delete_book(book_id: str, db: Session = Depends(get_db)):
    book_obj = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")
    db.delete(book_obj)
    db.commit()
    return None


@router.get("/trending", response_model=List[book_schema.Book])
def get_trending_books(db: Session = Depends(get_db)):
    time_threshold = datetime.now(timezone.utc) - timedelta(days=7)

    trending_books = (
        db.query(book_model.Book, func.count(Interaction.id).label("interaction_count"))
        .join(Interaction, Interaction.book_id == book_model.Book.id)
        .filter(Interaction.created_at >= time_threshold)
        .group_by(book_model.Book.id)
        .order_by(text("interaction_count DESC"))
        .limit(10)
        .all()
    )
    return [_book_to_response(b[0]) for b in trending_books]


@router.get("/recommended/{user_id}", response_model=List[book_schema.Book])
def get_recommended_books(user_id: str, db: Session = Depends(get_db)):
    user_categories = (
        db.query(category_model.Category.id)
        .join(
            book_model.Book, category_model.Category.id == book_model.Book.category_id
        )
        .join(Interaction, Interaction.book_id == book_model.Book.id)
        .filter(Interaction.user_id == user_id)
        .all()
    )

    if not user_categories:
        return get_trending_books(db)

    categories = [c[0] for c in user_categories]

    recommendations = (
        db.query(book_model.Book)
        .filter(book_model.Book.category_id.in_(categories))
        .filter(
            ~book_model.Book.id.in_(
                db.query(Interaction.book_id).filter(Interaction.user_id == user_id)
            )
        )
        .limit(10)
        .all()
    )
    return [_book_to_response(b) for b in recommendations]
