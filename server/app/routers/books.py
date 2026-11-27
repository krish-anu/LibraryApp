from datetime import datetime, timedelta, timezone
from typing import List, cast
from uuid import uuid4

from fastapi import APIRouter, Body, Depends, Header, HTTPException
from sqlalchemy import func, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.api.dependencies import (
    get_db,
    require_admin_scope,
    require_scope,
    require_subject_or_admin,
)
from app.services.images import image_response, validate_image_body
from ..models import author as author_model
from ..models import book as book_model
from ..models import category as category_model
from ..models.interactions import Interaction
from ..pydantic_schemas import book as book_schema

router = APIRouter(prefix="/books", tags=["books"])


def _author_name_parts(name: str) -> tuple[str, str]:
    parts = name.strip().split()
    if not parts:
        return "Unknown", ""
    if len(parts) == 1:
        return parts[0], ""
    return " ".join(parts[:-1]), parts[-1]


def _find_or_create_author(db: Session, name: str) -> author_model.Author:
    first_name, last_name = _author_name_parts(name)
    author = (
        db.query(author_model.Author)
        .filter(
            func.lower(func.coalesce(author_model.Author.first_name, ""))
            == first_name.lower(),
            func.lower(func.coalesce(author_model.Author.last_name, ""))
            == last_name.lower(),
        )
        .first()
    )
    if author:
        return author
    author = author_model.Author(
        id=str(uuid4()), first_name=first_name, last_name=last_name
    )
    db.add(author)
    db.flush()
    return author


def _find_or_create_category(db: Session, name: str) -> category_model.Category:
    category = (
        db.query(category_model.Category)
        .filter(func.lower(category_model.Category.name) == name.strip().lower())
        .first()
    )
    if category:
        return category
    category = category_model.Category(id=str(uuid4()), name=name.strip())
    db.add(category)
    db.flush()
    return category


def _book_to_response(book_obj: book_model.Book) -> book_schema.Book:
    image = (
        f"/books/{book_obj.id}/image"
        if book_obj.image_blob is not None
        else str(book_obj.image or "")
    )
    return book_schema.Book(
        id=str(book_obj.id),
        title=str(book_obj.title or ""),
        author=str(book_obj.author or "Unknown"),
        category=str(book_obj.category or "Unknown"),
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
        image=image,
        language=str(book_obj.language or "English"),
        pages=(int(cast(int, book_obj.pages)) if book_obj.pages is not None else 200),
        rating_count=(
            int(cast(int, book_obj.rating_count))
            if book_obj.rating_count is not None
            else 0
        ),
    )


def _book_query(db: Session):
    return db.query(book_model.Book).options(
        selectinload(book_model.Book.author_rel),
        selectinload(book_model.Book.category_rel),
    )


@router.get("", response_model=List[book_schema.Book])
def get_books(
    _identity: dict = Depends(require_scope("books_read")),
    db: Session = Depends(get_db),
):
    books = _book_query(db).all()
    return [_book_to_response(book) for book in books]


@router.post("", response_model=book_schema.Book, status_code=201)
def create_book(
    book_data: book_schema.BookCreate,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    existing_category = _find_or_create_category(db, book_data.category)
    author = _find_or_create_author(db, book_data.author)

    new_book = book_model.Book(
        id=str(uuid4()),
        title=book_data.title,
        author_id=author.id,
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
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Book data conflicts with an existing record") from exc
    db.refresh(new_book)
    return _book_to_response(new_book)


def _trending_books(db: Session) -> list[book_schema.Book]:
    time_threshold = datetime.now(timezone.utc) - timedelta(days=7)

    trending_books = (
        db.query(book_model.Book, func.count(Interaction.id).label("interaction_count"))
        .options(
            selectinload(book_model.Book.author_rel),
            selectinload(book_model.Book.category_rel),
        )
        .join(Interaction, Interaction.book_id == book_model.Book.id)
        .filter(Interaction.created_at >= time_threshold)
        .group_by(book_model.Book.id)
        .order_by(text("interaction_count DESC"))
        .limit(10)
        .all()
    )
    return [_book_to_response(book[0]) for book in trending_books]


@router.get("/trending", response_model=List[book_schema.Book])
def get_trending_books(
    _identity: dict = Depends(require_scope("books_read")),
    db: Session = Depends(get_db),
):
    return _trending_books(db)


@router.get("/recommended/{user_id}", response_model=List[book_schema.Book])
def get_recommended_books(
    user_id: str,
    identity: dict = Depends(require_scope("books_read")),
    db: Session = Depends(get_db),
):
    require_subject_or_admin(identity, user_id)
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
        return _trending_books(db)

    categories = [category[0] for category in user_categories]

    recommendations = (
        _book_query(db)
        .filter(book_model.Book.category_id.in_(categories))
        .filter(
            ~book_model.Book.id.in_(
                db.query(Interaction.book_id).filter(Interaction.user_id == user_id)
            )
        )
        .limit(10)
        .all()
    )
    return [_book_to_response(book) for book in recommendations]


@router.get("/{book_id}/image")
def get_book_image(book_id: str, db: Session = Depends(get_db)):
    book_obj = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")
    if book_obj.image_blob is None:
        raise HTTPException(status_code=404, detail="Book image not found")
    return image_response(book_obj.image_blob, book_obj.image_mime_type)


@router.put("/{book_id}/image", response_model=book_schema.Book)
async def upload_book_image(
    book_id: str,
    body: bytes = Body(...),
    content_type: str | None = Header(default=None),
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    book_obj = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")

    body, mime_type = validate_image_body(body, content_type)
    book_obj.image_blob = body
    book_obj.image_mime_type = mime_type
    book_obj.image = f"/books/{book_id}/image"
    db.commit()
    db.refresh(book_obj)
    return _book_to_response(book_obj)


@router.delete("/{book_id}/image", response_model=book_schema.Book)
def delete_book_image(
    book_id: str,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    book_obj = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")

    book_obj.image_blob = None
    book_obj.image_mime_type = None
    if book_obj.image == f"/books/{book_id}/image":
        book_obj.image = None
    db.commit()
    db.refresh(book_obj)
    return _book_to_response(book_obj)


@router.get("/{book_id}", response_model=book_schema.Book)
def get_book(
    book_id: str,
    _identity: dict = Depends(require_scope("books_read")),
    db: Session = Depends(get_db),
):
    book_obj = _book_query(db).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")
    return _book_to_response(book_obj)


@router.put("/{book_id}", response_model=book_schema.Book)
def update_book(
    book_id: str,
    book_data: book_schema.BookCreate,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    book_obj = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")

    category = _find_or_create_category(db, book_data.category)
    author = _find_or_create_author(db, book_data.author)
    book_obj.category_id = category.id
    book_obj.author_id = author.id

    book_obj.title = book_data.title
    book_obj.description = book_data.description
    book_obj.rating = book_data.rating
    book_obj.publication_year = book_data.publication_year
    book_obj.copies_owned = book_data.copies_owned
    book_obj.image = book_data.image
    book_obj.language = book_data.language
    book_obj.pages = book_data.pages
    book_obj.rating_count = book_data.rating_count

    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Book data conflicts with an existing record") from exc
    db.refresh(book_obj)
    return _book_to_response(book_obj)


@router.delete("/{book_id}", status_code=204)
def delete_book(
    book_id: str,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    book_obj = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not book_obj:
        raise HTTPException(status_code=404, detail="Book not found")
    db.delete(book_obj)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Books with loan, reservation, or interaction history cannot be deleted",
        ) from exc
    return None
