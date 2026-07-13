from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.services.sheet_sync.service import normalize_spreadsheet_id


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
    sheet_sync_enabled: bool = False
    sheet_sync_interval_days: int = Field(default=30, ge=1, le=365)
    sheet_spreadsheet_id: str | None = Field(default=None, max_length=256)
    sheet_books_tab: str | None = Field(default="Books", max_length=128)
    sheet_blogs_tab: str | None = Field(default="Blogs", max_length=128)
    sheet_videos_tab: str | None = Field(default="Videos", max_length=128)

    @field_validator("sheet_spreadsheet_id", mode="before")
    @classmethod
    def normalize_sheet_spreadsheet_id(cls, value: object) -> str | None:
        normalized = normalize_spreadsheet_id(value)
        return normalized or None


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
    sheet_sync_enabled: Optional[bool] = None
    sheet_sync_interval_days: Optional[int] = Field(default=None, ge=1, le=365)
    sheet_spreadsheet_id: Optional[str] = Field(default=None, max_length=256)
    sheet_books_tab: Optional[str] = Field(default=None, max_length=128)
    sheet_blogs_tab: Optional[str] = Field(default=None, max_length=128)
    sheet_videos_tab: Optional[str] = Field(default=None, max_length=128)

    @field_validator("sheet_spreadsheet_id", mode="before")
    @classmethod
    def normalize_sheet_spreadsheet_id(cls, value: object) -> str | None:
        normalized = normalize_spreadsheet_id(value)
        return normalized or None


class Settings(SettingsBase):
    id: str
    created_at: datetime | None = None
    updated_at: datetime | None = None
    sheet_last_sync_at: datetime | None = None
    sheet_last_sync_status: str | None = None
    sheet_last_sync_message: str | None = None

    model_config = ConfigDict(from_attributes=True)
