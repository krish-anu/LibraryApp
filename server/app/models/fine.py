from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Numeric, TEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .loan import Loan
    from .users import User


class Fine(Base):
    __tablename__ = "fines"
    __table_args__ = (
        CheckConstraint("fine_amount IS NULL OR fine_amount >= 0", name="ck_fines_amount_nonnegative"),
        CheckConstraint(
            "status IS NULL OR lower(status) IN ('unpaid', 'paid', 'waived')",
            name="ck_fines_status",
        ),
    )

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    member_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("users.id"))
    loan_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("loans.id"))
    fine_date: Mapped[date | None] = mapped_column(Date)
    fine_amount: Mapped[float | None] = mapped_column(Numeric)
    status: Mapped[str | None] = mapped_column(TEXT, default="unpaid")
    reason: Mapped[str | None] = mapped_column(TEXT)
    due_date: Mapped[date | None] = mapped_column(Date)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime)
    payment_method: Mapped[str | None] = mapped_column(TEXT)
    created_at: Mapped[datetime | None] = mapped_column(DateTime)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime)

    member: Mapped[User | None] = relationship("User")
    loan: Mapped[Loan | None] = relationship("Loan")
