from pydantic import BaseModel, field_serializer
from typing import Optional
from datetime import date


class ReservationBase(BaseModel):
    book_id: str
    member_id: str
    reservation_date: Optional[str] = None
    status: Optional[str] = None


class ReservationCreate(ReservationBase):
    pass


class Reservation(BaseModel):
    id: str
    book_id: str
    member_id: str
    reservation_date: Optional[date] = None
    status: Optional[str] = None

    @field_serializer('reservation_date')
    def serialize_date(self, value: date | None) -> str | None:
        if value is None:
            return None
        return value.isoformat()

    class Config:
        from_attributes = True
