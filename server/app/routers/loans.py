from datetime import date, timedelta
from typing import Any, List, Optional, cast

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..dependencies import get_db, verify_access_token
from ..models import (
    book as book_model,
    fine as fine_model,
    loan,
    settings as settings_model,
    users as user_model,
)
from ..pydantic_schemas import loan as loan_schema

router = APIRouter(
    prefix="/loans", tags=["loans"], dependencies=[Depends(verify_access_token)]
)


@router.get("", response_model=List[loan_schema.Loan])
def get_loans(db: Session = Depends(get_db)):
    return db.query(loan.Loan).all()


@router.get("/active", response_model=List[loan_schema.Loan])
def get_active_loans(member_id: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(loan.Loan)
    if member_id:
        query = query.filter(loan.Loan.member_id == member_id)
    return query.all()


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
def borrow_book(book_id: str, member_id: str, db: Session = Depends(get_db)):
    existing_loan = (
        db.query(loan.Loan)
        .filter(loan.Loan.book_id == book_id, loan.Loan.member_id == member_id)
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
        db.query(loan.Loan).filter(loan.Loan.member_id == member_id).count()
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
    return new_loan


@router.post("/return/{loan_id}")
def return_book(loan_id: str, db: Session = Depends(get_db)):
    db_loan = cast(Any, db.query(loan.Loan).filter(loan.Loan.id == loan_id).first())
    if not db_loan:
        raise HTTPException(status_code=404, detail="Loan not found")

    db_book = cast(
        Any,
        db.query(book_model.Book).filter(book_model.Book.id == db_loan.book_id).first(),
    )
    if db_book:
        db_book.copies_owned = int(cast(Any, db_book.copies_owned) or 0) + 1

    db.delete(db_loan)
    db.commit()

    return {"message": "Book returned successfully"}


@router.post("/renew/{loan_id}", response_model=loan_schema.Loan)
def renew_loan(
    loan_id: str,
    db: Session = Depends(get_db),
):
    db_loan = cast(Any, db.query(loan.Loan).filter(loan.Loan.id == loan_id).first())
    if not db_loan:
        raise HTTPException(status_code=404, detail="Loan not found")

    loan_period_days = _loan_period_days(db)
    db_loan.returned_date = date.today() + timedelta(days=loan_period_days)
    db.commit()
    db.refresh(db_loan)

    return db_loan
