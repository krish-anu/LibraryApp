from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import datetime, date
import uuid

from ..dependencies import get_db, verify_access_token
from ..models import reservation as reservation_model
from ..models import loan as loan_model
from ..pydantic_schemas import reservation as reservation_schema

router = APIRouter(prefix="", tags=["reservations"], dependencies=[Depends(verify_access_token)])  # mount multiple paths manually


@router.get("/reservations", response_model=List[reservation_schema.Reservation])
def list_reservations(db: Session = Depends(get_db)):
    return db.query(reservation_model.Reservation).all()


@router.get(
    "/reservations/{reservation_id}", response_model=reservation_schema.Reservation
)
def get_reservation(reservation_id: str, db: Session = Depends(get_db)):
    r = (
        db.query(reservation_model.Reservation)
        .filter(reservation_model.Reservation.id == reservation_id)
        .first()
    )
    if not r:
        raise HTTPException(status_code=404, detail="Reservation not found")
    return r


@router.get(
    "/reservations/member/{member_id}",
    response_model=List[reservation_schema.Reservation],
)
def get_reservations_for_member(member_id: str, db: Session = Depends(get_db)):
    return (
        db.query(reservation_model.Reservation)
        .filter(reservation_model.Reservation.member_id == member_id)
        .all()
    )


@router.post(
    "/reservations", response_model=reservation_schema.Reservation, status_code=201
)
def create_reservation(
    res_in: reservation_schema.ReservationCreate, db: Session = Depends(get_db)
):
    # A member cannot reserve a book they already borrowed and not yet returned.
    existing_loan = (
        db.query(loan_model.Loan)
        .filter(
            loan_model.Loan.book_id == res_in.book_id,
            loan_model.Loan.member_id == res_in.member_id,
        )
        .first()
    )
    if existing_loan:
        raise HTTPException(
            status_code=409,
            detail="You already borrowed this book. Return it before reserving.",
        )

    # A member cannot reserve the same book more than once while reservation is active.
    inactive_reservation_statuses = (
        "cancelled",
        "canceled",
        "expired",
        "completed",
        "fulfilled",
    )
    existing_reservation = (
        db.query(reservation_model.Reservation)
        .filter(
            reservation_model.Reservation.book_id == res_in.book_id,
            reservation_model.Reservation.member_id == res_in.member_id,
        )
        .filter(
            (reservation_model.Reservation.status.is_(None))
            | (
                ~func.lower(reservation_model.Reservation.status).in_(
                    inactive_reservation_statuses
                )
            )
        )
        .first()
    )
    if existing_reservation:
        raise HTTPException(
            status_code=409,
            detail="You already reserved this book.",
        )

    # prepare fields
    rid = uuid.uuid4().hex
    reservation_date = None
    if res_in.reservation_date:
        try:
            # accept ISO date string
            reservation_date = datetime.fromisoformat(res_in.reservation_date).date()
        except Exception:
            try:
                reservation_date = datetime.strptime(
                    res_in.reservation_date, "%Y-%m-%d"
                ).date()
            except Exception:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid reservation_date format; expected ISO YYYY-MM-DD",
                )

    r = reservation_model.Reservation(
        id=rid,
        book_id=res_in.book_id,
        member_id=res_in.member_id,
        reservation_date=reservation_date,
        status=res_in.status,
    )
    db.add(r)
    db.commit()
    db.refresh(r)
    return r
