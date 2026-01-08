from pydantic import BaseModel
from typing import Optional


class BookBase(BaseModel):
    title: str
    author: str
    category: str
    description: str
    rating: float
    publication_year: int
    copies_owned: int
    image: str


class BookCreate(BookBase):
    pass


class Book(BookBase):
    id: str

    class Config:
        from_attributes = True
