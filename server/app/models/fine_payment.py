from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Numeric, TEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .fine import Fine
    from .users import User


class FinePayment(Base):
    __tablename__ = "fine_payments"
    __table_args__ = (
        CheckConstraint(
            "payment_amount IS NULL OR payment_amount > 0",
            name="ck_fine_payments_amount_positive",
        ),
    )

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    fine_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("fines.id"))
    member_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("users.id"))
    payment_date: Mapped[date | None] = mapped_column(Date)
    payment_amount: Mapped[float | None] = mapped_column(Numeric)
    payment_method: Mapped[str | None] = mapped_column(TEXT)
    handled_by: Mapped[str | None] = mapped_column(TEXT)
    notes: Mapped[str | None] = mapped_column(TEXT)
    created_at: Mapped[datetime | None] = mapped_column(DateTime)

    fine: Mapped[Fine | None] = relationship("Fine")
    member: Mapped[User | None] = relationship("User")
