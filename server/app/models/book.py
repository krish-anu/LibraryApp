from .base import Base
from sqlalchemy import Column, TEXT, NUMERIC, ForeignKey
from sqlalchemy.orm import relationship


class Book(Base):
    __tablename__ = "books"

    id = Column(TEXT, primary_key=True)
    title = Column(TEXT)
    author_id = Column(TEXT, ForeignKey("authors.id"))
    category_id = Column(TEXT, ForeignKey("categories.id"))
    description = Column(TEXT)
    rating = Column(NUMERIC)
    publication_year = Column(NUMERIC)
    copies_owned = Column(NUMERIC)
    image = Column(TEXT)
    language = Column(TEXT, default="English")
    pages = Column(NUMERIC, default=200)
    rating_count = Column(NUMERIC, default=0)

    category_rel = relationship("Category", back_populates="books")
    author_rel = relationship("Author", back_populates="books")

    @property
    def category(self):
        return self.category_rel.name if self.category_rel else None

    @property
    def author(self):
        if not self.author_rel:
            return None
        first = self.author_rel.first_name or ""
        last = self.author_rel.last_name or ""
        name = f"{first} {last}".strip()
        return name if name else None
