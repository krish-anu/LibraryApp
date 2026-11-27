from __future__ import annotations

from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field


class FineCreate(BaseModel):
    member_id: str
    loan_id: str | None = None
    fine_amount: Decimal = Field(gt=0, decimal_places=2, allow_inf_nan=False)
    fine_date: date
    due_date: date | None = None
    reason: str = "Manual fine"


class FineUpdate(BaseModel):
    status: str | None = None
    payment_amount: Decimal | None = Field(
        default=None, gt=0, decimal_places=2, allow_inf_nan=False
    )
    payment_method: str | None = None
    notes: str | None = None
