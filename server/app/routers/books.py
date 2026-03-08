from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text, func
from typing import List, cast
from datetime import datetime, timedelta, timezone

from ..dependencies import get_db, verify_access_token
from ..models import book
from ..models import category as category_model
from ..models.interactions import Interaction
from ..pydantic_schemas import book as book_schema

router = APIRouter(prefix="/books", tags=["books"], dependencies=[Depends(verify_access_token)])


def _book_to_response(book_obj: book.Book) -> book_schema.Book:
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
    books = db.query(book.Book).all()
    return [_book_to_response(b) for b in books]


@router.get("/trending", response_model=List[book_schema.Book])
def get_trending_books(db: Session = Depends(get_db)):
    time_threshold = datetime.now(timezone.utc) - timedelta(days=7)

    trending_books = (
        db.query(book.Book, func.count(Interaction.id).label("interaction_count"))
        .join(Interaction, Interaction.book_id == book.Book.id)
        .filter(Interaction.created_at >= time_threshold)
        .group_by(book.Book.id)
        .order_by(text("interaction_count DESC"))
        .limit(10)
        .all()
    )
    return [_book_to_response(b[0]) for b in trending_books]


@router.get("/recommended/{user_id}", response_model=List[book_schema.Book])
def get_recommended_books(user_id: str, db: Session = Depends(get_db)):
    # 1. Find the categories the user has interacted with most
    # query the Category.id via join (book.Book.category is a python property)
    user_categories = (
        db.query(category_model.Category.id)
        .join(book.Book, category_model.Category.id == book.Book.category_id)
        .join(Interaction, Interaction.book_id == book.Book.id)
        .filter(Interaction.user_id == user_id)
        .all()
    )

    if not user_categories:
        # Fallback: If new user or no history, show trending
        return get_trending_books(db)

    categories = [c[0] for c in user_categories]

    # 2. Recommend books in those categories that the user hasn't read/interacted with
    recommendations = (
        db.query(book.Book)
        .filter(book.Book.category_id.in_(categories))
        # Exclude books the user already interacted with
        .filter(
            ~book.Book.id.in_(
                db.query(Interaction.book_id).filter(Interaction.user_id == user_id)
            )
        )
        .limit(10)
        .all()
    )
    return [_book_to_response(b) for b in recommendations]
