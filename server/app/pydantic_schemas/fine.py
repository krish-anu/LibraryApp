from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field


class FineCreate(BaseModel):
    member_id: str
    loan_id: str | None = None
    fine_amount: float = Field(gt=0)
    fine_date: date
    due_date: date | None = None
    reason: str = "Manual fine"


class FineUpdate(BaseModel):
    status: str | None = None
    payment_amount: float | None = Field(default=None, gt=0)
    payment_method: str | None = None
    notes: str | None = None
