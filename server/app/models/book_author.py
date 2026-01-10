from .base import Base
from sqlalchemy import Column, TEXT, ForeignKey


class BookAuthor(Base):
    __tablename__ = "book_author"

    book_id = Column(TEXT, ForeignKey("books.id"), primary_key=True)
    author_id = Column(TEXT, ForeignKey("authors.id"), primary_key=True)
