from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Index, TEXT, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .book import Book
    from .users import User


class Reservation(Base):
    __tablename__ = "reservations"
    __table_args__ = (
        CheckConstraint(
            "status IS NULL OR lower(status) IN "
            "('pending', 'ready', 'cancelled', 'canceled', 'expired', 'completed', 'fulfilled')",
            name="ck_reservations_status",
        ),
        Index(
            "uq_reservations_active_member_book",
            "member_id",
            "book_id",
            unique=True,
            postgresql_where=text(
                "status IS NULL OR lower(status) IN ('pending', 'ready')"
            ),
        ),
    )

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    book_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("books.id"))
    member_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("users.id"))
    reservation_date: Mapped[date | None] = mapped_column(Date)
    queued_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str | None] = mapped_column(TEXT, default="pending")

    book: Mapped[Book | None] = relationship("Book")
    member: Mapped[User | None] = relationship("User")


def reservation_queue_order():
    return (
        Reservation.queued_at.asc().nullsfirst(),
        Reservation.reservation_date.asc().nullsfirst(),
        Reservation.id.asc(),
    )
