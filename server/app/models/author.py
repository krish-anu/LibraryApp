from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import TEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .book import Book


class Author(Base):
    __tablename__ = "authors"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    first_name: Mapped[str | None] = mapped_column(TEXT)
    last_name: Mapped[str | None] = mapped_column(TEXT)

    books: Mapped[list[Book]] = relationship("Book", back_populates="author_rel")
