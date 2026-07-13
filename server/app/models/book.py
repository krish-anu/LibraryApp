from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, LargeBinary, NUMERIC, TEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .author import Author
    from .category import Category


class Book(Base):
    __tablename__ = "books"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    title: Mapped[str | None] = mapped_column(TEXT)
    subtitle: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    author_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("authors.id"))
    category_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("categories.id"))
    description: Mapped[str | None] = mapped_column(TEXT)
    publisher: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    isbn_10: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    isbn_13: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    rating: Mapped[float | None] = mapped_column(NUMERIC)
    publication_year: Mapped[int | None] = mapped_column(NUMERIC)
    copies_owned: Mapped[int | None] = mapped_column(NUMERIC)
    image: Mapped[str | None] = mapped_column(TEXT)
    image_blob: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)
    image_mime_type: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    language: Mapped[str | None] = mapped_column(TEXT, default="English")
    pages: Mapped[int | None] = mapped_column(NUMERIC, default=200)
    rating_count: Mapped[int | None] = mapped_column(NUMERIC, default=0)
    tags: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    published_date: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    edition: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    book_url: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    featured: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    sort_order: Mapped[int | None] = mapped_column(NUMERIC, nullable=True)
    sheet_created_at: Mapped[str | None] = mapped_column(TEXT, nullable=True)

    category_rel: Mapped[Category | None] = relationship(
        "Category", back_populates="books"
    )
    author_rel: Mapped[Author | None] = relationship("Author", back_populates="books")

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
