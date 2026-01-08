from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from .database import SessionLocal, engine
from .models.base import Base
from .models import book, users, loan
from .pydantic_schemas import book as book_schema
from .pydantic_schemas import loan as loan_schema
from typing import List
from .models.interactions import Interaction


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="Library App API", lifespan=lifespan)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/")
def root():
    return {"message": "Hello, FastAPI + Supabase is working!"}


@app.get("/books", response_model=List[book_schema.Book])
def get_books(db: Session = Depends(get_db)):
    return db.query(book.Book).all()


@app.get("/loans", response_model=List[loan_schema.Loan])
def get_loans(db: Session = Depends(get_db)):
    return db.query(loan.Loan).all()

from sqlalchemy import func
from datetime import datetime, timedelta


@app.get("/books/trending")
def get_trending_books(db: Session = Depends(get_db)):
    time_threshold = datetime.utcnow() - timedelta(days=7)

    trending_books = (
        db.query(book.Book, func.count(Interaction.id).label("interaction_count"))
        .join(Interaction)
        .filter(Interaction.created_at >= time_threshold)
        .group_by(book.Book.id)
        .order_by(text("interaction_count DESC"))
        .limit(10)
        .all()
    )
    return [b[0] for b in trending_books]


@app.get("/books/recommended/{user_id}")
def get_recommended_books(user_id: int, db: Session = Depends(get_db)):
    # 1. Find the genres the user has interacted with most
    user_genres = (
        db.query(book.Book.genre)
        .join(Interaction)
        .filter(Interaction.user_id == user_id)
        .all()
    )

    if not user_genres:
        # Fallback: If new user, show top rated or trending
        return get_trending_books(db)

    genres = [g[0] for g in user_genres]

    # 2. Recommend books in those genres that the user hasn't read
    recommendations = (
        db.query(book.Book)
        .filter(book.Book.genre.in_(genres))
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


@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT 1")).scalar()
    return {"result": result}
