from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
from datetime import date, timedelta
import uuid

from ..dependencies import get_db
from ..models import loan, book as book_model
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


@router.post("/borrow", response_model=loan_schema.Loan)
def borrow_book(book_id: str, member_id: str, db: Session = Depends(get_db)):
    """Create a new loan for borrowing a book."""
    # Check if book exists and has available copies
    db_book = db.query(book_model.Book).filter(book_model.Book.id == book_id).first()
    if not db_book:
        raise HTTPException(status_code=404, detail="Book not found")

    if db_book.copies_owned <= 0:
        raise HTTPException(status_code=400, detail="No copies available")

    # Use UUID-based IDs to avoid collisions from lexicographic string sorting.
    new_id = f"l{uuid.uuid4().hex}"

    # Create new loan (14 day loan period)
    new_loan = loan.Loan(
        id=new_id,
        book_id=book_id,
        member_id=member_id,
        loan_date=date.today(),
        returned_date=date.today() + timedelta(days=14),
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

    # Extend return date by 14 days from today
    db_loan.returned_date = date.today() + timedelta(days=14)
    db.commit()
    db.refresh(db_loan)

    return db_loan
