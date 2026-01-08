from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text, func
from typing import List
from datetime import datetime, timedelta, timezone

from ..dependencies import get_db
from ..models import book
from ..models.interactions import Interaction
from ..pydantic_schemas import book as book_schema

router = APIRouter(prefix="/books", tags=["books"])


@router.get("", response_model=List[book_schema.Book])
def get_books(db: Session = Depends(get_db)):
    return db.query(book.Book).all()


@router.get("/trending")
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
    return [b[0] for b in trending_books]


@router.get("/recommended/{user_id}")
def get_recommended_books(user_id: str, db: Session = Depends(get_db)):
    # 1. Find the categories the user has interacted with most
    user_categories = (
        db.query(book.Book.category)
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
        .filter(book.Book.category.in_(categories))
        # Exclude books the user already interacted with
        .filter(
            ~book.Book.id.in_(
                db.query(Interaction.book_id).filter(Interaction.user_id == user_id)
            )
        )
        .limit(10)
        .all()
    )
    return recommendations
