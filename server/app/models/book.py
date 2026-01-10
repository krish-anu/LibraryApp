from .base import Base
from sqlalchemy import Column, TEXT, NUMERIC, ForeignKey
from sqlalchemy.orm import relationship


class Book(Base):
    __tablename__ = "books"

    id = Column(TEXT, primary_key=True)
    title = Column(TEXT)
    author = Column(TEXT)
    category_id = Column(TEXT, ForeignKey("categories.id"))
    description = Column(TEXT)
    rating = Column(NUMERIC)
    publication_year = Column(NUMERIC)
    copies_owned = Column(NUMERIC)
    image = Column(TEXT)

    category_rel = relationship("Category", back_populates="books")
    authors = relationship("Author", secondary="book_author", back_populates="books")

    @property
    def category(self):
        return self.category_rel.name if self.category_rel else None
