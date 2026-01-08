from .base import Base
from sqlalchemy import Column, TEXT, NUMERIC


class Book(Base):
    __tablename__ = "books"

    id = Column(TEXT, primary_key=True)
    title = Column(TEXT)
    author = Column(TEXT)
    category = Column(TEXT)
    description = Column(TEXT)
    rating = Column(NUMERIC)
    publication_year = Column(NUMERIC)
    copies_owned = Column(NUMERIC)
    image = Column(TEXT)
