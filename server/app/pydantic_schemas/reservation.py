from pydantic import BaseModel, ConfigDict, field_serializer, field_validator
from typing import Optional
from datetime import date


class ReservationBase(BaseModel):
    book_id: str
    member_id: str
    reservation_date: Optional[str] = None
    status: Optional[str] = "pending"

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str | None) -> str:
        normalized = (value or "pending").strip().lower()
        if normalized not in {"pending", "ready"}:
            raise ValueError("new reservations must use pending or ready status")
        return normalized


class ReservationCreate(ReservationBase):
    pass


class Reservation(BaseModel):
    id: str
    book_id: str
    member_id: str
    reservation_date: Optional[date] = None
    status: Optional[str] = None

    @field_serializer("reservation_date")
    def serialize_date(self, value: date | None) -> str | None:
        if value is None:
            return None
        return value.isoformat()

    model_config = ConfigDict(from_attributes=True)
