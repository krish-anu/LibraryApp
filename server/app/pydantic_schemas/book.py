from pydantic import BaseModel
from typing import Optional


class BookBase(BaseModel):
    title: str
    category: str
    publication_year: int
    copies_owned: int


class BookCreate(BookBase):
    pass


class Book(BookBase):
    id: str

    class Config:
        from_attributes = True
