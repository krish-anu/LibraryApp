from __future__ import annotations

from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Date, ForeignKey, TEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .book import Book
    from .users import User


class Reservation(Base):
    __tablename__ = "reservations"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    book_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("books.id"))
    member_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("users.id"))
    reservation_date: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str | None] = mapped_column(TEXT)

    book: Mapped[Book | None] = relationship("Book")
    member: Mapped[User | None] = relationship("User")
