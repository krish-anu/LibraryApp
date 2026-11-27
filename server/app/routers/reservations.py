from datetime import date, datetime, timezone
from typing import List
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.dependencies import (
    get_db,
    require_admin_scope,
    require_scope,
    require_subject_or_admin,
)
from app.services.notifications import create_admin_notification, create_user_notification
from ..models import book as book_model
from ..models import loan as loan_model
from ..models import reservation as reservation_model
from ..models import users as user_model
from ..pydantic_schemas import reservation as reservation_schema

router = APIRouter(prefix="", tags=["reservations"])


def _safe_notify(callback) -> None:
    try:
        callback()
    except Exception:
        return


def _active_reservation_filter():
    return func.lower(
        func.coalesce(reservation_model.Reservation.status, "pending")
    ).in_(("pending", "ready"))


def _active_loan_filter():
    return func.lower(func.coalesce(loan_model.Loan.status, "active")) == "active"


@router.get("/reservations", response_model=List[reservation_schema.Reservation])
def list_reservations(
    active_only: bool = False,
    _admin: dict = Depends(require_admin_scope("reservations_read")),
    db: Session = Depends(get_db),
):
    query = db.query(reservation_model.Reservation)
    if active_only:
        query = query.filter(_active_reservation_filter())
    return query.order_by(*reservation_model.reservation_queue_order()).all()


@router.get(
    "/reservations/{reservation_id}", response_model=reservation_schema.Reservation
)
def get_reservation(
    reservation_id: str,
    identity: dict = Depends(require_scope("reservations_read")),
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
    identity: dict = Depends(require_scope("reservations_read")),
    db: Session = Depends(get_db),
):
    require_subject_or_admin(identity, member_id)
    return (
        db.query(reservation_model.Reservation)
        .filter(
            reservation_model.Reservation.member_id == member_id,
            _active_reservation_filter(),
        )
        .order_by(*reservation_model.reservation_queue_order())
        .all()
    )


@router.post(
    "/reservations", response_model=reservation_schema.Reservation, status_code=201
)
def create_reservation(
    res_in: reservation_schema.ReservationCreate,
    identity: dict = Depends(require_scope("reservations_manage")),
    db: Session = Depends(get_db),
):
    require_subject_or_admin(identity, res_in.member_id)
    member = (
        db.query(user_model.User)
        .filter(user_model.User.id == res_in.member_id)
        .with_for_update()
        .first()
    )
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    book = (
        db.query(book_model.Book)
        .filter(book_model.Book.id == res_in.book_id)
        .with_for_update()
        .first()
    )
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    existing_loan = (
        db.query(loan_model.Loan)
        .filter(
            loan_model.Loan.book_id == res_in.book_id,
            loan_model.Loan.member_id == res_in.member_id,
            _active_loan_filter(),
        )
        .first()
    )
    if existing_loan:
        raise HTTPException(
            status_code=409,
            detail="You already borrowed this book. Return it before reserving.",
        )

    active_reservations = (
        db.query(reservation_model.Reservation)
        .filter(
            reservation_model.Reservation.book_id == res_in.book_id,
            _active_reservation_filter(),
        )
        .with_for_update()
        .all()
    )
    if any(item.member_id == res_in.member_id for item in active_reservations):
        raise HTTPException(status_code=409, detail="You already reserved this book.")
    ready_holds = sum(
        1
        for item in active_reservations
        if str(item.status or "pending").lower() == "ready"
    )
    if int(book.copies_owned or 0) > ready_holds:
        raise HTTPException(
            status_code=409,
            detail="This book is currently available to borrow and cannot be reserved.",
        )

    reservation_date = date.today()
    if res_in.reservation_date:
        try:
            reservation_date = datetime.fromisoformat(res_in.reservation_date).date()
        except ValueError as exc:
            raise HTTPException(
                status_code=400,
                detail="Invalid reservation_date format; expected ISO YYYY-MM-DD",
            ) from exc

    reservation = reservation_model.Reservation(
        id=str(uuid4()),
        book_id=res_in.book_id,
        member_id=res_in.member_id,
        reservation_date=reservation_date,
        queued_at=datetime.now(timezone.utc),
        status="pending",
    )
    db.add(reservation)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409, detail="An active reservation already exists."
        ) from exc
    db.refresh(reservation)

    book_title = str(book.title or "the selected book")
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
                "reservation_date": reservation.reservation_date.isoformat(),
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
    "/reservations/{reservation_id}", response_model=reservation_schema.Reservation
)
def cancel_reservation(
    reservation_id: str,
    identity: dict = Depends(require_scope("reservations_manage")),
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
    book = (
        db.query(book_model.Book)
        .filter(book_model.Book.id == reservation.book_id)
        .with_for_update()
        .first()
    )
    reservation = (
        db.query(reservation_model.Reservation)
        .filter(reservation_model.Reservation.id == reservation_id)
        .populate_existing()
        .with_for_update()
        .first()
    )
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    if str(reservation.status or "pending").lower() not in {"pending", "ready"}:
        raise HTTPException(status_code=409, detail="Reservation is no longer active")

    reservation.status = "cancelled"
    next_reservation = None
    if book is not None:
        remaining = (
            db.query(reservation_model.Reservation)
            .filter(
                reservation_model.Reservation.book_id == reservation.book_id,
                reservation_model.Reservation.id != reservation.id,
                _active_reservation_filter(),
            )
            .order_by(*reservation_model.reservation_queue_order())
            .with_for_update()
            .all()
        )
        ready_count = sum(
            1
            for item in remaining
            if str(item.status or "pending").lower() == "ready"
        )
        if int(book.copies_owned or 0) > ready_count:
            next_reservation = next(
                (
                    item
                    for item in remaining
                    if str(item.status or "pending").lower() == "pending"
                ),
                None,
            )
            if next_reservation is not None:
                next_reservation.status = "ready"
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise
    db.refresh(reservation)

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
    if next_reservation is not None:
        _safe_notify(
            lambda: create_user_notification(
                str(next_reservation.member_id),
                title="Reserved book available",
                body=f'"{book_title}" is now available for you to borrow.',
                category="reservation_ready",
                entity_type="reservation",
                entity_id=str(next_reservation.id),
                metadata={
                    "book_id": str(reservation.book_id),
                    "book_title": book_title,
                },
                dedupe_key=f"reservation-ready:{next_reservation.id}",
                send_push=True,
            )
        )
    return reservation
