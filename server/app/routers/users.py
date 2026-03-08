from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List

from app.dependencies import get_db, verify_access_token
from app.models.users import User as UserModel
from app.models.loan import Loan as LoanModel
from app.models.fine import Fine as FineModel
from app.models.reservation import Reservation as ReservationModel
from app.pydantic_schemas import user as user_schema

router = APIRouter(prefix="/users", tags=["users"], dependencies=[Depends(verify_access_token)])


@router.get("/{user_id}", response_model=user_schema.User)
def get_user(user_id: str, db: Session = Depends(get_db)):
    """Fetch a user by database `id`."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("/by-member/{member_id}", response_model=user_schema.User)
def get_user_by_member(member_id: str, db: Session = Depends(get_db)):
    """Fetch a user by `member_id` field."""
    user = db.query(UserModel).filter(UserModel.member_id == member_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.put("/{user_id}", response_model=user_schema.User)
def update_user(
    user_id: str, user_update: user_schema.UserUpdate, db: Session = Depends(get_db)
):
    """Update user profile information."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    update_data = user_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if value is not None:
            setattr(user, key, value)

    db.commit()
    db.refresh(user)
    return user


@router.get("/{user_id}/stats", response_model=user_schema.ProfileStats)
def get_user_stats(user_id: str, db: Session = Depends(get_db)):
    """Get user profile statistics."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Total borrows (all loans ever)
    total_borrows = (
        db.query(func.count(LoanModel.id))
        .filter(LoanModel.member_id == user_id)
        .scalar()
        or 0
    )

    # Active loans (currently borrowed)
    active_loans = (
        db.query(func.count(LoanModel.id))
        .filter(LoanModel.member_id == user_id)
        .scalar()
        or 0
    )

    # Books read = total_borrows for now (assuming returned books are read)
    books_read = total_borrows

    # Total fines
    total_fines = (
        db.query(func.coalesce(func.sum(FineModel.fine_amount), 0))
        .filter(
            FineModel.member_id == user_id,
            func.lower(func.coalesce(FineModel.status, "unpaid")) == "unpaid",
        )
        .scalar()
        or 0.0
    )

    # Active reservations
    active_reservations = (
        db.query(func.count(ReservationModel.id))
        .filter(ReservationModel.member_id == user_id)
        .scalar()
        or 0
    )

    return user_schema.ProfileStats(
        total_borrows=total_borrows,
        books_read=books_read,
        total_fines=float(total_fines),
        active_loans=active_loans,
        active_reservations=active_reservations,
    )
