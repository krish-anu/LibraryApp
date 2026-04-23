from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..dependencies import get_db, verify_access_token
from ..models.book import Book
from ..models.interactions import Interaction
from ..pydantic_schemas import book as book_schema

router = APIRouter(
    prefix="/favorites", tags=["favorites"], dependencies=[Depends(verify_access_token)]
)


@router.get("/{member_id}", response_model=List[book_schema.Book])
def get_favorites(member_id: str, db: Session = Depends(get_db)):
    favorites = (
        db.query(Interaction)
        .filter(
            Interaction.user_id == member_id, Interaction.interaction_type == "like"
        )
        .all()
    )

    book_ids = [favorite.book_id for favorite in favorites]
    books = db.query(Book).filter(Book.id.in_(book_ids)).all() if book_ids else []
    return books


@router.get("/{member_id}/ids")
def get_favorite_ids(member_id: str, db: Session = Depends(get_db)):
    favorites = (
        db.query(Interaction)
        .filter(
            Interaction.user_id == member_id, Interaction.interaction_type == "like"
        )
        .all()
    )

    return {"book_ids": [favorite.book_id for favorite in favorites]}


@router.post("/{member_id}/{book_id}")
def add_favorite(member_id: str, book_id: str, db: Session = Depends(get_db)):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    existing = (
        db.query(Interaction)
        .filter(
            Interaction.user_id == member_id,
            Interaction.book_id == book_id,
            Interaction.interaction_type == "like",
        )
        .first()
    )

    if existing:
        return {"message": "Book already in favorites", "is_favorite": True}

    interaction = Interaction(
        user_id=member_id,
        book_id=book_id,
        interaction_type="like",
        created_at=datetime.now(timezone.utc),
    )
    db.add(interaction)
    db.commit()

    return {"message": "Book added to favorites", "is_favorite": True}


@router.delete("/{member_id}/{book_id}")
def remove_favorite(member_id: str, book_id: str, db: Session = Depends(get_db)):
    favorite = (
        db.query(Interaction)
        .filter(
            Interaction.user_id == member_id,
            Interaction.book_id == book_id,
            Interaction.interaction_type == "like",
        )
        .first()
    )

    if not favorite:
        return {"message": "Book not in favorites", "is_favorite": False}

    db.delete(favorite)
    db.commit()

    return {"message": "Book removed from favorites", "is_favorite": False}


@router.get("/{member_id}/{book_id}/check")
def check_favorite(member_id: str, book_id: str, db: Session = Depends(get_db)):
    favorite = (
        db.query(Interaction)
        .filter(
            Interaction.user_id == member_id,
            Interaction.book_id == book_id,
            Interaction.interaction_type == "like",
        )
        .first()
    )

    return {"is_favorite": favorite is not None}
