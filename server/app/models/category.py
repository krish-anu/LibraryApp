from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import TEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .book import Book


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    name: Mapped[str | None] = mapped_column(TEXT)
    image_url: Mapped[str | None] = mapped_column(TEXT)

    books: Mapped[list[Book]] = relationship("Book", back_populates="category_rel")
