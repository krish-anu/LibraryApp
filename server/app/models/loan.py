from __future__ import annotations

from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, Integer, TEXT, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .book import Book
    from .users import User


class Loan(Base):
    __tablename__ = "loans"
    __table_args__ = (
        CheckConstraint(
            "status IS NULL OR lower(status) IN ('active', 'returned')",
            name="ck_loans_status",
        ),
        CheckConstraint("renewal_count >= 0", name="ck_loans_renewal_count"),
        Index(
            "uq_loans_active_member_book",
            "member_id",
            "book_id",
            unique=True,
            postgresql_where=text("lower(coalesce(status, 'active')) = 'active'"),
        ),
    )

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    book_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("books.id"))
    member_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("users.id"))
    loan_date: Mapped[date | None] = mapped_column(Date)
    returned_date: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str | None] = mapped_column(TEXT, default="active")
    returned_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    returned_by: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    renewal_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    book: Mapped[Book | None] = relationship("Book")
    member: Mapped[User | None] = relationship("User")
