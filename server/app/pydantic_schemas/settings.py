from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class SettingsBase(BaseModel):
    loan_period_days: int = Field(default=14, gt=0)
    max_books_per_user: int = Field(default=5, gt=0)
    grace_period_days: int = Field(default=2, ge=0)
    daily_fine_rate: float = Field(default=0.50, ge=0)
    max_fine_cap: float = Field(default=25.00, ge=0)
    block_on_unpaid_fines: bool = True
    fine_threshold: float = Field(default=10.00, ge=0)
    send_notifications: bool = True
    notification_days_before_due: int = Field(default=3, ge=0)


class SettingsUpdate(BaseModel):
    loan_period_days: Optional[int] = Field(default=None, gt=0)
    max_books_per_user: Optional[int] = Field(default=None, gt=0)
    grace_period_days: Optional[int] = Field(default=None, ge=0)
    daily_fine_rate: Optional[float] = Field(default=None, ge=0)
    max_fine_cap: Optional[float] = Field(default=None, ge=0)
    block_on_unpaid_fines: Optional[bool] = None
    fine_threshold: Optional[float] = Field(default=None, ge=0)
    send_notifications: Optional[bool] = None
    notification_days_before_due: Optional[int] = Field(default=None, ge=0)


class Settings(SettingsBase):
    id: str
    created_at: datetime | None = None
    updated_at: datetime | None = None

    class Config:
        from_attributes = True
