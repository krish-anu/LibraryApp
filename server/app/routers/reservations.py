from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from ..dependencies import get_db, require_admin, require_subject_or_admin, verify_access_token
from ..models import loan as loan_model
from ..models import reservation as reservation_model
from ..models import book as book_model
from ..notification_center import create_admin_notification, create_user_notification
from ..pydantic_schemas import reservation as reservation_schema

router = APIRouter(prefix="", tags=["reservations"])


def _safe_notify(callback) -> None:
    try:
        callback()
    except Exception:
        # Notification delivery should never block reservation actions.
        return


@router.get("/reservations", response_model=List[reservation_schema.Reservation])
def list_reservations(
    _admin: dict = Depends(require_admin), db: Session = Depends(get_db)
):
    return db.query(reservation_model.Reservation).all()


@router.get(
    "/reservations/{reservation_id}", response_model=reservation_schema.Reservation
)
def get_reservation(
    reservation_id: str,
    identity: dict = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    reservation = (
        db.query(reservation_model.Reservation)
        .filter(reservation_model.Reservation.id == reservation_id)
        .first()
    )
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    require_subject_or_admin(identity, str(reservation.member_id or ""))
    return reservation


@router.get(
    "/reservations/member/{member_id}",
    response_model=List[reservation_schema.Reservation],
)
def get_reservations_for_member(
    member_id: str,
    identity: dict = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    require_subject_or_admin(identity, member_id)
    return (
        db.query(reservation_model.Reservation)
        .filter(reservation_model.Reservation.member_id == member_id)
        .all()
    )


@router.post(
    "/reservations", response_model=reservation_schema.Reservation, status_code=201
)
def create_reservation(
    res_in: reservation_schema.ReservationCreate,
    identity: dict = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    require_subject_or_admin(identity, res_in.member_id)
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

    reservation_id = f'r{__import__("random").randint(100000, 999999)}'
    reservation_date = None
    if res_in.reservation_date:
        try:
            reservation_date = datetime.fromisoformat(res_in.reservation_date).date()
        except Exception:
            try:
                reservation_date = datetime.strptime(
                    res_in.reservation_date, "%Y-%m-%d"
                ).date()
            except Exception as exc:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid reservation_date format; expected ISO YYYY-MM-DD",
                ) from exc

    reservation = reservation_model.Reservation(
        id=reservation_id,
        book_id=res_in.book_id,
        member_id=res_in.member_id,
        reservation_date=reservation_date,
        status=res_in.status,
    )
    db.add(reservation)
    db.commit()
    db.refresh(reservation)

    book = (
        db.query(book_model.Book).filter(book_model.Book.id == res_in.book_id).first()
    )
    book_title = str(getattr(book, "title", None) or "the selected book")
    _safe_notify(
        lambda: create_user_notification(
            str(res_in.member_id),
            title="Reservation placed",
            body=f'Your reservation for "{book_title}" has been created.',
            category="reservation_created",
            entity_type="reservation",
            entity_id=str(reservation.id),
            metadata={
                "book_id": str(res_in.book_id),
                "book_title": book_title,
                "reservation_date": (
                    reservation.reservation_date.isoformat()
                    if reservation.reservation_date
                    else None
                ),
                "status": reservation.status,
            },
            dedupe_key=f"reservation-created:{reservation.id}",
            send_push=True,
        )
    )
    _safe_notify(
        lambda: create_admin_notification(
            title="New reservation",
            body=f'A member reserved "{book_title}".',
            category="reservation_created",
            entity_type="reservation",
            entity_id=str(reservation.id),
            metadata={
                "member_id": str(res_in.member_id),
                "book_id": str(res_in.book_id),
                "book_title": book_title,
                "status": reservation.status,
            },
            dedupe_key=f"admin-reservation-created:{reservation.id}",
        )
    )
    return reservation


@router.delete(
    "/reservations/{reservation_id}",
    response_model=reservation_schema.Reservation,
)
def cancel_reservation(
    reservation_id: str,
    identity: dict = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    reservation = (
        db.query(reservation_model.Reservation)
        .filter(reservation_model.Reservation.id == reservation_id)
        .first()
    )
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    require_subject_or_admin(identity, str(reservation.member_id or ""))

    reservation.status = "Cancelled"
    db.commit()
    db.refresh(reservation)

    book = (
        db.query(book_model.Book)
        .filter(book_model.Book.id == reservation.book_id)
        .first()
    )
    book_title = str(getattr(book, "title", None) or "the selected book")
    _safe_notify(
        lambda: create_user_notification(
            str(reservation.member_id),
            title="Reservation cancelled",
            body=f'Your reservation for "{book_title}" was cancelled.',
            category="reservation_cancelled",
            entity_type="reservation",
            entity_id=str(reservation.id),
            metadata={
                "book_id": str(reservation.book_id),
                "book_title": book_title,
                "status": reservation.status,
            },
            dedupe_key=f"reservation-cancelled:{reservation.id}",
            send_push=True,
        )
    )
    _safe_notify(
        lambda: create_admin_notification(
            title="Reservation cancelled",
            body=f'The reservation for "{book_title}" was cancelled.',
            category="reservation_cancelled",
            entity_type="reservation",
            entity_id=str(reservation.id),
            metadata={
                "member_id": str(reservation.member_id),
                "book_id": str(reservation.book_id),
                "book_title": book_title,
                "status": reservation.status,
            },
            dedupe_key=f"admin-reservation-cancelled:{reservation.id}",
        )
    )

    return reservation
