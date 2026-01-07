from .base import Base
from sqlalchemy import Column, TEXT, NUMERIC


class Book(Base):
    __tablename__ = "books"

    id = Column(TEXT, primary_key=True)
    title = Column(TEXT)
    category = Column(TEXT)
    publication_year = Column(NUMERIC)
    copies_owned = Column(NUMERIC)
