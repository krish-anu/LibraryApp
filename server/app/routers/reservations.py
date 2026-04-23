from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from ..dependencies import get_store, verify_access_token
from ..firestore_store import LibraryStore
from ..pydantic_schemas import reservation as reservation_schema
from ..router_utils import raise_store_http_error


router = APIRouter(
    prefix="", tags=["reservations"], dependencies=[Depends(verify_access_token)]
)


class ReservationCreateCompat(BaseModel):
    book_id: str | None = Field(default=None, alias="bookId")
    member_id: str | None = Field(default=None, alias="memberId")
    reservation_date: str | None = Field(default=None, alias="reservationDate")
    status: str | None = None

    model_config = ConfigDict(populate_by_name=True)


@router.get("/reservations", response_model=List[reservation_schema.Reservation])
def list_reservations(store: LibraryStore = Depends(get_store)):
    try:
        return store.list_reservations()
    except Exception as error:
        raise_store_http_error(error)


@router.get(
    "/reservations/{reservation_id}",
    response_model=reservation_schema.Reservation,
)
def get_reservation(
    reservation_id: str,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.get_reservation(reservation_id)
    except Exception as error:
        raise_store_http_error(error)


@router.get(
    "/reservations/member/{member_id}",
    response_model=List[reservation_schema.Reservation],
)
def get_reservations_for_member(
    member_id: str,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.get_reservations_for_member(member_id)
    except Exception as error:
        raise_store_http_error(error)


@router.post(
    "/reservations",
    response_model=reservation_schema.Reservation,
    status_code=201,
)
def create_reservation(
    payload: ReservationCreateCompat,
    store: LibraryStore = Depends(get_store),
    current_user: dict = Depends(verify_access_token),
):
    resolved_member_id = payload.member_id or current_user.get("sub")
    if not payload.book_id or not resolved_member_id:
        raise HTTPException(status_code=400, detail="book_id and member_id are required")

    try:
        return store.create_reservation(
            {
                "book_id": payload.book_id,
                "member_id": resolved_member_id,
                "reservation_date": payload.reservation_date,
                "status": payload.status,
            }
        )
    except Exception as error:
        raise_store_http_error(error)


@router.delete("/reservations/{reservation_id}")
def cancel_reservation(
    reservation_id: str,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.cancel_reservation(reservation_id)
    except Exception as error:
        raise_store_http_error(error)
