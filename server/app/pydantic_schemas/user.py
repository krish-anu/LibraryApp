from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from typing import Optional


class User(BaseModel):
    id: str
    member_id: str | None = None
    name: str | None = None
    email: str | None = None
    phone: str | None = None
    address: str | None = None
    profile_image: str | None = None
    joined_date: date | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    profile_image: Optional[str] = None


class ProfileStats(BaseModel):
    total_borrows: int = 0
    books_read: int = 0
    total_fines: float = 0.0
    active_loans: int = 0
    active_reservations: int = 0
