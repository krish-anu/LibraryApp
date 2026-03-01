from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func
from typing import List
from datetime import date, timedelta
import uuid

from ..dependencies import get_db
from ..models import loan, book as book_model, settings as settings_model, fine as fine_model
from ..pydantic_schemas import loan as loan_schema

router = APIRouter(prefix="/loans", tags=["loans"])


@router.get("", response_model=List[loan_schema.Loan])
def get_loans(db: Session = Depends(get_db)):
    return db.query(loan.Loan).all()


@router.get("/active", response_model=List[loan_schema.Loan])
def get_active_loans(member_id: str = None, db: Session = Depends(get_db)):
    """Get active loans (not yet returned). Optionally filter by member_id."""
    query = db.query(loan.Loan)
    if member_id:
        query = query.filter(loan.Loan.member_id == member_id)
    # Active loans: returned_date is in the future or loan is still ongoing
    return query.all()


def _get_settings(db: Session) -> settings_model.Settings | None:
    return (
        db.query(settings_model.Settings)
        .order_by(settings_model.Settings.created_at.asc())
        .first()
    )


def _loan_period_days(db: Session) -> int:
    row = _get_settings(db)
    if not row or row.loan_period_days is None:
        return 14
    return max(1, int(row.loan_period_days))


def _max_books_per_user(db: Session) -> int:
    row = _get_settings(db)
    if not row or row.max_books_per_user is None:
        return 5
    return max(1, int(row.max_books_per_user))


def _borrow_block_threshold(db: Session) -> float | None:
    row = _get_settings(db)
    if not row or not bool(row.block_on_unpaid_fines):
        return None
    if row.fine_threshold is None:
        return 0.0
    return float(row.fine_threshold)


@router.post("/borrow", response_model=loan_schema.Loan)
def borrow_book(book_id: str, member_id: str, db: Session = Depends(get_db)):
    """Create a new loan for borrowing a book."""
    # A member cannot borrow the same book again until the current loan is returned.
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

    max_books_allowed = _max_books_per_user(db)
    active_loans_count = db.query(loan.Loan).filter(loan.Loan.member_id == member_id).count()
    if active_loans_count >= max_books_allowed:
        raise HTTPException(
            status_code=400,
            detail=f"Borrowing limit reached. Maximum books per user is {max_books_allowed}.",
        )

    fine_threshold = _borrow_block_threshold(db)
    if fine_threshold is not None:
        total_fines = (
            db.query(func.coalesce(func.sum(fine_model.Fine.fine_amount), 0))
            .filter(fine_model.Fine.member_id == member_id)
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

    # Check if book exists and has available copies
    db_book = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not db_book:
        raise HTTPException(status_code=404, detail="Book not found")

    if db_book.copies_owned <= 0:
        raise HTTPException(status_code=400, detail="No copies available")

    # Use UUID-based IDs to avoid collisions from lexicographic string sorting.
    new_id = f"l{uuid.uuid4().hex}"

    loan_period_days = _loan_period_days(db)
    # Create new loan (based on settings loan period)
    new_loan = loan.Loan(
        id=new_id,
        book_id=book_id,
        member_id=member_id,
        loan_date=date.today(),
        returned_date=date.today() + timedelta(days=loan_period_days),
    )

    # Decrease available copies
    db_book.copies_owned -= 1

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
    """Return a borrowed book."""
    db_loan = db.query(loan.Loan).filter(loan.Loan.id == loan_id).first()
    if not db_loan:
        raise HTTPException(status_code=404, detail="Loan not found")

    # Increase book copies
    db_book = (
        db.query(book_model.Book).filter(book_model.Book.id == db_loan.book_id).first()
    )
    if db_book:
        db_book.copies_owned += 1

    # Delete the loan record
    db.delete(db_loan)
    db.commit()

    return {"message": "Book returned successfully"}


@router.post("/renew/{loan_id}", response_model=loan_schema.Loan)
def renew_loan(loan_id: str, db: Session = Depends(get_db)):
    """Renew a loan for another 14 days."""
    db_loan = db.query(loan.Loan).filter(loan.Loan.id == loan_id).first()
    if not db_loan:
        raise HTTPException(status_code=404, detail="Loan not found")

    # Extend return date using settings loan period.
    loan_period_days = _loan_period_days(db)
    db_loan.returned_date = date.today() + timedelta(days=loan_period_days)
    db.commit()
    db.refresh(db_loan)

    return db_loan
