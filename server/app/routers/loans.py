from datetime import date, timedelta
from typing import Any, List, Optional, cast

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.sql.elements import ColumnElement
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..dependencies import (
    get_db,
    identity_is_admin,
    require_admin,
    require_subject_or_admin,
    verify_access_token,
)
from ..models import (
    book as book_model,
    fine as fine_model,
    loan,
    settings as settings_model,
    users as user_model,
)
from ..notification_center import create_admin_notification, create_user_notification
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
def get_loans(_admin: dict = Depends(require_admin), db: Session = Depends(get_db)):
    return db.query(loan.Loan).all()


@router.get("/active", response_model=List[loan_schema.Loan])
def get_active_loans(
    member_id: Optional[str] = None,
    identity: dict = Depends(verify_access_token),
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
    _admin: dict = Depends(require_admin),
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
    _admin: dict = Depends(require_admin),
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


def _borrow_block_threshold(db: Session) -> float | None:
    row = _get_settings(db)
    if not row or not bool(row.block_on_unpaid_fines):
        return None
    if row.fine_threshold is None:
        return 0.0
    return float(cast(Any, row.fine_threshold))


def _is_blank(value: str | None) -> bool:
    return value is None or value.strip() == ""


@router.post("/borrow", response_model=loan_schema.Loan)
def borrow_book(
    book_id: str,
    member_id: str,
    identity: dict = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    require_subject_or_admin(identity, member_id)
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

    user = cast(
        Any, db.query(user_model.User).filter(user_model.User.id == member_id).first()
    )
    if not user:
        raise HTTPException(status_code=404, detail="Member not found")

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
        if total_fines_float >= fine_threshold:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Borrowing blocked due to unpaid fines above threshold. "
                    f"Current fines: {total_fines_float:.2f}, "
                    f"threshold: {fine_threshold:.2f}."
                ),
            )

    db_book = cast(
        Any, db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    )
    if not db_book:
        raise HTTPException(status_code=404, detail="Book not found")

    current_copies_owned = int(cast(Any, db_book.copies_owned) or 0)
    if current_copies_owned <= 0:
        raise HTTPException(status_code=400, detail="No copies available")

    new_id = f'l{__import__("random").randint(100000, 999999)}'

    loan_period_days = _loan_period_days(db)
    new_loan = loan.Loan(
        id=new_id,
        book_id=book_id,
        member_id=member_id,
        loan_date=date.today(),
        returned_date=date.today() + timedelta(days=loan_period_days),
        status="active",
        returned_at=None,
    )

    db_book.copies_owned = current_copies_owned - 1

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
    identity: dict = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    db_loan = cast(Any, db.query(loan.Loan).filter(loan.Loan.id == loan_id).first())
    if not db_loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    require_subject_or_admin(identity, str(cast(Any, db_loan.member_id) or ""))
    if str(cast(Any, db_loan.status) or "active").lower() == "returned":
        raise HTTPException(status_code=409, detail="Loan is already returned")

    db_book = cast(
        Any,
        db.query(book_model.Book).filter(book_model.Book.id == db_loan.book_id).first(),
    )
    if db_book:
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
    db.commit()

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

    return {
        "message": "Book returned successfully",
        "status": "Returned",
        "loan_id": str(loan_id),
        "returned_at": db_loan.returned_at.isoformat(),
        "returned_by": returned_by,
    }


@router.post("/renew/{loan_id}", response_model=loan_schema.Loan)
def renew_loan(
    loan_id: str,
    identity: dict = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    db_loan = cast(Any, db.query(loan.Loan).filter(loan.Loan.id == loan_id).first())
    if not db_loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    require_subject_or_admin(identity, str(cast(Any, db_loan.member_id) or ""))
    if str(cast(Any, db_loan.status) or "active").lower() == "returned":
        raise HTTPException(status_code=409, detail="Returned loans cannot be renewed")

    loan_period_days = _loan_period_days(db)
    db_loan.returned_date = date.today() + timedelta(days=loan_period_days)
    db.commit()
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
