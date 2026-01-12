from pydantic import BaseModel
from typing import Optional


class ReservationBase(BaseModel):
    book_id: str
    member_id: str
    reservation_date: Optional[str] = None
    status: Optional[str] = None


class ReservationCreate(ReservationBase):
    pass


class Reservation(ReservationBase):
    id: str

    class Config:
        from_attributes = True
