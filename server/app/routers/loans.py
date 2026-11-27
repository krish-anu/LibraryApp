from datetime import date, datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from typing import Any, List, Optional, cast
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.sql.elements import ColumnElement
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.dependencies import (
    get_db,
    identity_is_admin,
    require_admin_scope,
    require_scope,
    require_subject_or_admin,
)
from ..models import (
    book as book_model,
    fine as fine_model,
    loan,
    reservation as reservation_model,
    settings as settings_model,
    users as user_model,
)
from app.services.notifications import create_admin_notification, create_user_notification
from ..pydantic_schemas import loan as loan_schema

router = APIRouter(prefix="/loans", tags=["loans"])


class ReturnBookPayload(BaseModel):
    returned_by: Optional[str] = None


def _safe_notify(callback) -> None:
    try:
        callback()
    except Exception:
        # Notification delivery should never break the circulation flow.
        return


def _active_loan_filter() -> ColumnElement[bool]:
    return func.lower(func.coalesce(loan.Loan.status, "active")) == "active"


def _loan_detail(db_loan: Any, book: Any, user: Any) -> dict[str, Any]:
    return {
        "id": str(db_loan.id),
        "book_id": str(db_loan.book_id),
        "member_id": str(db_loan.member_id),
        "loan_date": db_loan.loan_date,
        "returned_date": db_loan.returned_date,
        "status": db_loan.status or "active",
        "returned_at": db_loan.returned_at,
        "returned_by": db_loan.returned_by,
        "book": {
            "id": str(book.id),
            "title": book.title or "Untitled book",
            "author": book.author,
            "copies_owned": int(book.copies_owned or 0),
            "image": book.image,
        },
        "member": {
            "id": str(user.id),
            "member_id": user.member_id,
            "name": user.name or "Unknown member",
            "email": user.email,
            "phone": user.phone,
        },
    }


@router.get("", response_model=List[loan_schema.Loan])
def get_loans(
    _admin: dict = Depends(require_admin_scope("loans_read")),
    db: Session = Depends(get_db),
):
    return db.query(loan.Loan).all()


@router.get("/active", response_model=List[loan_schema.Loan])
def get_active_loans(
    member_id: Optional[str] = None,
    identity: dict = Depends(require_scope("loans_read")),
    db: Session = Depends(get_db),
):
    query = db.query(loan.Loan).filter(_active_loan_filter())
    if member_id:
        require_subject_or_admin(identity, member_id)
        query = query.filter(loan.Loan.member_id == member_id)
    elif not identity_is_admin(identity):
        raise HTTPException(
            status_code=403,
            detail="member_id is required unless you are an administrator",
        )
    return query.all()


@router.get("/active/details")
def get_active_loan_details(
    _admin: dict = Depends(require_admin_scope("loans_read")),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(loan.Loan, book_model.Book, user_model.User)
        .join(book_model.Book, book_model.Book.id == loan.Loan.book_id)
        .join(user_model.User, user_model.User.id == loan.Loan.member_id)
        .filter(_active_loan_filter())
        .order_by(loan.Loan.loan_date.desc(), loan.Loan.id.asc())
        .all()
    )

    data = [_loan_detail(db_loan, book, user) for db_loan, book, user in rows]
    return {"data": data, "totalCount": len(data)}


@router.get("/history")
def get_loan_history(
    status: Optional[str] = None,
    _admin: dict = Depends(require_admin_scope("loans_read")),
    db: Session = Depends(get_db),
):
    query = (
        db.query(loan.Loan, book_model.Book, user_model.User)
        .join(book_model.Book, book_model.Book.id == loan.Loan.book_id)
        .join(user_model.User, user_model.User.id == loan.Loan.member_id)
    )

    normalized_status = (status or "").strip().lower()
    if normalized_status:
        query = query.filter(
            func.lower(func.coalesce(loan.Loan.status, "active"))
            == normalized_status
        )

    rows = (
        query.order_by(
            loan.Loan.loan_date.desc(),
            loan.Loan.returned_at.desc().nullslast(),
            loan.Loan.id.asc(),
        )
        .all()
    )
    data = [_loan_detail(db_loan, book, user) for db_loan, book, user in rows]
    return {"data": data, "totalCount": len(data)}


def _get_settings(db: Session) -> Any | None:
    row = (
        db.query(settings_model.Settings)
        .order_by(settings_model.Settings.created_at.asc())
        .first()
    )
    return cast(Any, row)


def _loan_period_days(db: Session) -> int:
    row = _get_settings(db)
    if not row or row.loan_period_days is None:
        return 14
    return max(1, int(cast(Any, row.loan_period_days)))


def _max_books_per_user(db: Session) -> int:
    row = _get_settings(db)
    if not row or row.max_books_per_user is None:
        return 5
    return max(1, int(cast(Any, row.max_books_per_user)))


def _max_renewals(db: Session) -> int:
    row = _get_settings(db)
    if not row or getattr(row, "max_renewals", None) is None:
        return 1
    return max(0, int(cast(Any, row.max_renewals)))


def _borrow_block_threshold(db: Session) -> float | None:
    row = _get_settings(db)
    if not row or not bool(row.block_on_unpaid_fines):
        return None
    if row.fine_threshold is None:
        return 0.0
    return float(cast(Any, row.fine_threshold))


def _is_blank(value: str | None) -> bool:
    return value is None or value.strip() == ""


def _active_reservation_filter() -> ColumnElement[bool]:
    return func.lower(func.coalesce(reservation_model.Reservation.status, "pending")).in_(
        ("pending", "ready")
    )


def _create_overdue_fine(
    db: Session, db_loan: Any, returned_on: date
) -> tuple[Any | None, bool]:
    due_date = cast(date | None, db_loan.returned_date)
    if due_date is None:
        return None, False
    settings = _get_settings(db)
    grace_days = max(0, int(getattr(settings, "grace_period_days", 2) or 0))
    overdue_days = (returned_on - due_date).days - grace_days
    if overdue_days <= 0:
        return None, False

    existing = (
        db.query(fine_model.Fine)
        .filter(fine_model.Fine.loan_id == db_loan.id)
        .with_for_update()
        .first()
    )
    if existing:
        return existing, False

    daily_rate = Decimal(str(getattr(settings, "daily_fine_rate", 0.50) or 0))
    max_cap = Decimal(str(getattr(settings, "max_fine_cap", 25.00) or 0))
    amount = daily_rate * overdue_days
    if max_cap > 0:
        amount = min(amount, max_cap)
    amount = amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    if amount <= 0:
        return None, False

    now = datetime.utcnow()
    fine = fine_model.Fine(
        id=str(uuid4()),
        member_id=db_loan.member_id,
        loan_id=db_loan.id,
        fine_date=returned_on,
        fine_amount=amount,
        status="unpaid",
        reason=f"Overdue by {overdue_days} day(s) after grace period",
        due_date=returned_on,
        created_at=now,
        updated_at=now,
    )
    db.add(fine)
    return fine, True


@router.post("/borrow", response_model=loan_schema.Loan)
def borrow_book(
    book_id: str,
    member_id: str,
    identity: dict = Depends(require_scope("loans_manage")),
    db: Session = Depends(get_db),
):
    require_subject_or_admin(identity, member_id)
    user = cast(
        Any,
        db.query(user_model.User)
        .filter(user_model.User.id == member_id)
        .with_for_update()
        .first(),
    )
    if not user:
        raise HTTPException(status_code=404, detail="Member not found")

    db_book = cast(
        Any,
        db.query(book_model.Book)
        .filter(book_model.Book.id == book_id)
        .with_for_update()
        .first(),
    )
    if not db_book:
        raise HTTPException(status_code=404, detail="Book not found")

    existing_loan = (
        db.query(loan.Loan)
        .filter(
            loan.Loan.book_id == book_id,
            loan.Loan.member_id == member_id,
            _active_loan_filter(),
        )
        .first()
    )
    if existing_loan:
        raise HTTPException(
            status_code=409,
            detail="You already borrowed this book. Return it before borrowing again.",
        )

    missing_mobile = _is_blank(cast(Optional[str], user.phone))
    missing_address = _is_blank(cast(Optional[str], user.address))
    if missing_mobile or missing_address:
        if missing_mobile and missing_address:
            detail = "Please update your mobile number and address before borrowing."
        elif missing_mobile:
            detail = "Please update your mobile number before borrowing."
        else:
            detail = "Please update your address before borrowing."
        raise HTTPException(status_code=400, detail=detail)

    max_books_allowed = _max_books_per_user(db)
    active_loans_count = (
        db.query(loan.Loan)
        .filter(
            loan.Loan.member_id == member_id,
            _active_loan_filter(),
        )
        .count()
    )
    if active_loans_count >= max_books_allowed:
        raise HTTPException(
            status_code=400,
            detail=f"Borrowing limit reached. Maximum books per user is {max_books_allowed}.",
        )

    fine_threshold = _borrow_block_threshold(db)
    if fine_threshold is not None:
        total_fines = (
            db.query(func.coalesce(func.sum(fine_model.Fine.fine_amount), 0))
            .filter(
                fine_model.Fine.member_id == member_id,
                func.lower(func.coalesce(fine_model.Fine.status, "unpaid")) == "unpaid",
            )
            .scalar()
        )
        total_fines_float = float(total_fines or 0)
        if total_fines_float > 0 and total_fines_float >= fine_threshold:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Borrowing blocked due to unpaid fines above threshold. "
                    f"Current fines: {total_fines_float:.2f}, "
                    f"threshold: {fine_threshold:.2f}."
                ),
            )

    current_copies_owned = int(cast(Any, db_book.copies_owned) or 0)
    if current_copies_owned <= 0:
        raise HTTPException(status_code=400, detail="No copies available")

    active_reservations = (
        db.query(reservation_model.Reservation)
        .filter(
            reservation_model.Reservation.book_id == book_id,
            _active_reservation_filter(),
        )
        .order_by(*reservation_model.reservation_queue_order())
        .with_for_update()
        .all()
    )
    member_reservation = next(
        (item for item in active_reservations if item.member_id == member_id), None
    )
    ready_holds = sum(
        1 for item in active_reservations if str(item.status or "pending").lower() == "ready"
    )
    ready_reservations = [
        item
        for item in active_reservations
        if str(item.status or "pending").lower() == "ready"
    ]
    pending_reservations = [
        item
        for item in active_reservations
        if str(item.status or "pending").lower() == "pending"
    ]
    unheld_copies = max(0, current_copies_owned - ready_holds)
    eligible_reservations = ready_reservations + pending_reservations[:unheld_copies]
    eligible_member_ids = {str(item.member_id) for item in eligible_reservations}
    queue_uses_all_copies = len(eligible_reservations) >= current_copies_owned
    if str(member_id) not in eligible_member_ids and queue_uses_all_copies:
        raise HTTPException(
            status_code=409,
            detail="This copy is reserved for a member earlier in the queue.",
        )

    loan_period_days = _loan_period_days(db)
    new_loan = loan.Loan(
        id=str(uuid4()),
        book_id=book_id,
        member_id=member_id,
        loan_date=date.today(),
        returned_date=date.today() + timedelta(days=loan_period_days),
        status="active",
        returned_at=None,
        renewal_count=0,
    )

    db_book.copies_owned = current_copies_owned - 1
    if member_reservation is not None:
        member_reservation.status = "fulfilled"

    db.add(new_loan)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Failed to create loan due to duplicate or conflicting data",
        )
    db.refresh(new_loan)

    book_title = str(cast(Any, db_book.title) or "your selected book")
    due_date = cast(date, new_loan.returned_date)
    _safe_notify(
        lambda: create_user_notification(
            member_id,
            title="Borrow successful",
            body=f'You borrowed "{book_title}". It is due on {due_date.isoformat()}.',
            category="borrowed",
            entity_type="loan",
            entity_id=str(new_loan.id),
            metadata={
                "book_id": str(book_id),
                "book_title": book_title,
                "due_date": due_date.isoformat(),
            },
            dedupe_key=f"borrowed:{new_loan.id}",
            send_push=True,
        )
    )
    _safe_notify(
        lambda: create_admin_notification(
            title="Book borrowed",
            body=f'A member borrowed "{book_title}".',
            category="borrowed",
            entity_type="loan",
            entity_id=str(new_loan.id),
            metadata={
                "member_id": str(member_id),
                "book_id": str(book_id),
                "book_title": book_title,
                "due_date": due_date.isoformat(),
            },
            dedupe_key=f"admin-borrowed:{new_loan.id}",
        )
    )
    return new_loan


@router.post("/return/{loan_id}")
def return_book(
    loan_id: str,
    payload: ReturnBookPayload | None = None,
    identity: dict = Depends(require_scope("loans_manage")),
    db: Session = Depends(get_db),
):
    db_loan = cast(
        Any,
        db.query(loan.Loan)
        .filter(loan.Loan.id == loan_id)
        .with_for_update()
        .first(),
    )
    if not db_loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    require_subject_or_admin(identity, str(cast(Any, db_loan.member_id) or ""))
    if str(cast(Any, db_loan.status) or "active").lower() == "returned":
        raise HTTPException(status_code=409, detail="Loan is already returned")

    db_book = cast(
        Any,
        db.query(book_model.Book)
        .filter(book_model.Book.id == db_loan.book_id)
        .with_for_update()
        .first(),
    )
    if not db_book:
        raise HTTPException(status_code=409, detail="The loan's book record is missing")
    db_book.copies_owned = int(cast(Any, db_book.copies_owned) or 0) + 1

    member_id = str(cast(Any, db_loan.member_id) or "")
    book_id = str(cast(Any, db_loan.book_id) or "")
    book_title = str(cast(Any, getattr(db_book, "title", None)) or "your borrowed book")
    returned_by = (
        payload.returned_by.strip()
        if payload and payload.returned_by and payload.returned_by.strip()
        else None
    )

    db_loan.status = "returned"
    db_loan.returned_at = date.today()
    db_loan.returned_by = returned_by
    overdue_fine, fine_created = _create_overdue_fine(db, db_loan, date.today())

    next_reservation = None
    active_reservations = (
        db.query(reservation_model.Reservation)
        .filter(
            reservation_model.Reservation.book_id == db_loan.book_id,
            _active_reservation_filter(),
        )
        .order_by(*reservation_model.reservation_queue_order())
        .with_for_update()
        .all()
    )
    ready_count = sum(
        1
        for item in active_reservations
        if str(item.status or "pending").lower() == "ready"
    )
    if int(cast(Any, db_book.copies_owned) or 0) > ready_count:
        next_reservation = next(
            (
                item
                for item in active_reservations
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

    if member_id:
        returned_by_text = f" by {returned_by}" if returned_by else ""
        _safe_notify(
            lambda: create_user_notification(
                member_id,
                title="Return confirmed",
                body=f'Your return for "{book_title}" was recorded{returned_by_text}.',
                category="returned",
                entity_type="loan",
                entity_id=str(loan_id),
                metadata={
                    "book_id": book_id,
                    "book_title": book_title,
                    "returned_by": returned_by,
                },
                dedupe_key=f"returned:{loan_id}",
                send_push=True,
            )
        )
    _safe_notify(
        lambda: create_admin_notification(
            title="Book returned",
            body=(
                f'"{book_title}" was returned by {returned_by}.'
                if returned_by
                else f'"{book_title}" was returned to the library.'
            ),
            category="returned",
            entity_type="loan",
            entity_id=str(loan_id),
            metadata={
                "member_id": member_id,
                "book_id": book_id,
                "book_title": book_title,
                "returned_by": returned_by,
            },
            dedupe_key=f"admin-returned:{loan_id}",
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
                metadata={"book_id": book_id, "book_title": book_title},
                dedupe_key=f"reservation-ready:{next_reservation.id}",
                send_push=True,
            )
        )

    return {
        "message": "Book returned successfully",
        "status": "Returned",
        "loan_id": str(loan_id),
        "returned_at": db_loan.returned_at.isoformat(),
        "returned_by": returned_by,
        "fine_created": fine_created,
        "fine_amount": float(overdue_fine.fine_amount or 0) if overdue_fine else 0.0,
    }


@router.post("/renew/{loan_id}", response_model=loan_schema.Loan)
def renew_loan(
    loan_id: str,
    identity: dict = Depends(require_scope("loans_manage")),
    db: Session = Depends(get_db),
):
    db_loan = cast(
        Any,
        db.query(loan.Loan)
        .filter(loan.Loan.id == loan_id)
        .with_for_update()
        .first(),
    )
    if not db_loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    require_subject_or_admin(identity, str(cast(Any, db_loan.member_id) or ""))
    if str(cast(Any, db_loan.status) or "active").lower() == "returned":
        raise HTTPException(status_code=409, detail="Returned loans cannot be renewed")

    due_date = cast(date | None, db_loan.returned_date)
    if due_date is not None and due_date < date.today():
        raise HTTPException(status_code=409, detail="Overdue loans cannot be renewed")

    renewal_count = int(cast(Any, getattr(db_loan, "renewal_count", 0)) or 0)
    max_renewals = _max_renewals(db)
    if renewal_count >= max_renewals:
        raise HTTPException(
            status_code=409,
            detail=f"Renewal limit reached. Maximum renewals is {max_renewals}.",
        )

    waiting_reservation = (
        db.query(reservation_model.Reservation)
        .filter(
            reservation_model.Reservation.book_id == db_loan.book_id,
            reservation_model.Reservation.member_id != db_loan.member_id,
            _active_reservation_filter(),
        )
        .with_for_update()
        .first()
    )
    if waiting_reservation:
        raise HTTPException(
            status_code=409,
            detail="This loan cannot be renewed because another member is waiting.",
        )

    loan_period_days = _loan_period_days(db)
    renewal_base = max(date.today(), due_date or date.today())
    db_loan.returned_date = renewal_base + timedelta(days=loan_period_days)
    db_loan.renewal_count = renewal_count + 1
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise
    db.refresh(db_loan)

    book = (
        db.query(book_model.Book).filter(book_model.Book.id == db_loan.book_id).first()
    )
    book_title = str(cast(Any, getattr(book, "title", None)) or "your borrowed book")
    due_date = cast(date, db_loan.returned_date)
    member_id = str(cast(Any, db_loan.member_id) or "").strip()
    if member_id:
        _safe_notify(
            lambda: create_user_notification(
                member_id,
                title="Loan renewed",
                body=f'Your loan for "{book_title}" was renewed until {due_date.isoformat()}.',
                category="renewed",
                entity_type="loan",
                entity_id=str(loan_id),
                metadata={
                    "book_id": str(cast(Any, db_loan.book_id) or ""),
                    "book_title": book_title,
                    "due_date": due_date.isoformat(),
                },
                dedupe_key=f"renewed:{loan_id}:{due_date.isoformat()}",
                send_push=True,
            )
        )
    _safe_notify(
        lambda: create_admin_notification(
            title="Loan renewed",
            body=f'"{book_title}" was renewed until {due_date.isoformat()}.',
            category="renewed",
            entity_type="loan",
            entity_id=str(loan_id),
            metadata={
                "member_id": member_id,
                "book_id": str(cast(Any, db_loan.book_id) or ""),
                "book_title": book_title,
                "due_date": due_date.isoformat(),
            },
            dedupe_key=f"admin-renewed:{loan_id}:{due_date.isoformat()}",
        )
    )

    return db_loan
