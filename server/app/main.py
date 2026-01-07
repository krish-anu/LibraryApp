from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from .database import SessionLocal, engine
from .models.base import Base
from .models import book, users
from .pydantic_schemas import book as book_schema
from typing import List


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


@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT 1")).scalar()
    return {"result": result}
