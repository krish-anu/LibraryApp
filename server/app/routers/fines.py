from __future__ import annotations

from datetime import date, datetime
from typing import Any
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from ..dependencies import get_db, identity_subject, require_admin
from ..models.book import Book
from ..models.fine import Fine
from ..models.fine_payment import FinePayment
from ..models.loan import Loan
from ..models.users import User
from ..pydantic_schemas.fine import FineCreate, FineUpdate

router = APIRouter(prefix="/fines", tags=["fines"])


def _serialize_fine(db: Session, fine: Fine) -> dict[str, Any]:
    user = db.query(User).filter(User.id == fine.member_id).first()
    loan = db.query(Loan).filter(Loan.id == fine.loan_id).first() if fine.loan_id else None
    book = db.query(Book).filter(Book.id == loan.book_id).first() if loan else None
    payments = (
        db.query(FinePayment)
        .filter(FinePayment.fine_id == fine.id)
        .order_by(FinePayment.created_at.desc(), FinePayment.payment_date.desc())
        .all()
    )
    total_paid = sum(float(payment.payment_amount or 0) for payment in payments)
    latest = payments[0] if payments else None
    user_total_due = float(
        db.query(func.coalesce(func.sum(Fine.fine_amount), 0))
        .filter(
            Fine.member_id == fine.member_id,
            func.lower(func.coalesce(Fine.status, "unpaid")) == "unpaid",
        )
        .scalar()
        or 0
    )
    remaining = float(fine.fine_amount or 0)

    return {
        "id": str(fine.id),
        "member_id": fine.member_id,
        "loan_id": fine.loan_id,
        "fine_date": fine.fine_date,
        "fine_amount": remaining,
        "status": fine.status or "unpaid",
        "reason": fine.reason,
        "due_date": fine.due_date,
        "paid_at": fine.paid_at,
        "payment_method": fine.payment_method,
        "created_at": fine.created_at,
        "updated_at": fine.updated_at,
        "user_name": user.name if user else None,
        "user_email": user.email if user else None,
        "book_title": book.title if book else None,
        "payment_date": latest.payment_date if latest else None,
        "payment_amount": float(latest.payment_amount or 0) if latest else 0,
        "payment_handled_by": latest.handled_by if latest else None,
        "payment_notes": latest.notes if latest else None,
        "total_paid": total_paid,
        "payment_count": len(payments),
        "total_fine_amount": remaining + total_paid,
        "user_total_due": user_total_due,
    }


def _find_fine(db: Session, fine_id: str) -> Fine:
    fine = db.query(Fine).filter(Fine.id == fine_id).first()
    if not fine:
        raise HTTPException(status_code=404, detail="Fine not found")
    return fine


@router.get("")
def list_fines(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=10, ge=1, le=100),
    search: str = "",
    status: str = "",
    _admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
    query = (
        db.query(Fine)
        .outerjoin(User, User.id == Fine.member_id)
        .outerjoin(Loan, Loan.id == Fine.loan_id)
        .outerjoin(Book, Book.id == Loan.book_id)
    )
    if status.strip():
        query = query.filter(func.lower(Fine.status) == status.strip().lower())
    if search.strip():
        pattern = f"%{search.strip()}%"
        query = query.filter(
            or_(
                Fine.id.ilike(pattern),
                Fine.member_id.ilike(pattern),
                Fine.loan_id.ilike(pattern),
                Fine.reason.ilike(pattern),
                User.name.ilike(pattern),
                User.email.ilike(pattern),
                Book.title.ilike(pattern),
            )
        )

    total = query.count()
    rows = (
        query.order_by(Fine.created_at.desc(), Fine.fine_date.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )
    return {
        "data": [_serialize_fine(db, fine) for fine in rows],
        "totalCount": total,
        "pagination": {"page": page, "limit": limit, "total": total},
    }


@router.post("", status_code=201)
def create_fine(
    payload: FineCreate,
    _admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
    if not db.query(User).filter(User.id == payload.member_id).first():
        raise HTTPException(status_code=404, detail="Member not found")
    if payload.loan_id:
        loan = db.query(Loan).filter(Loan.id == payload.loan_id).first()
        if not loan:
            raise HTTPException(status_code=404, detail="Loan not found")
        if loan.member_id != payload.member_id:
            raise HTTPException(status_code=400, detail="Loan does not belong to member")

    now = datetime.utcnow()
    fine = Fine(
        id=str(uuid4()),
        member_id=payload.member_id,
        loan_id=payload.loan_id,
        fine_date=payload.fine_date,
        fine_amount=payload.fine_amount,
        status="unpaid",
        reason=payload.reason.strip() or "Manual fine",
        due_date=payload.due_date,
        created_at=now,
        updated_at=now,
    )
    db.add(fine)
    db.commit()
    db.refresh(fine)
    return {"data": _serialize_fine(db, fine)}


@router.get("/{fine_id}")
def get_fine(
    fine_id: str,
    _admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
    return {"data": _serialize_fine(db, _find_fine(db, fine_id))}


@router.put("/{fine_id}")
def update_fine(
    fine_id: str,
    payload: FineUpdate,
    admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
    fine = _find_fine(db, fine_id)
    now = datetime.utcnow()

    if payload.status is not None:
        normalized_status = payload.status.strip().lower()
        if normalized_status not in {"unpaid", "paid", "waived"}:
            raise HTTPException(status_code=400, detail="Invalid fine status")
        fine.status = normalized_status
        fine.updated_at = now
        if normalized_status == "paid":
            fine.fine_amount = 0
            fine.paid_at = now

    payment_result = None
    if payload.payment_amount is not None:
        if (fine.status or "unpaid").lower() in {"paid", "waived"}:
            raise HTTPException(status_code=409, detail="This fine is already closed")
        current_due = float(fine.fine_amount or 0)
        amount = float(payload.payment_amount)
        if amount > current_due:
            raise HTTPException(
                status_code=400,
                detail=f"Payment exceeds the current due amount of {current_due:.2f}",
            )

        remaining = round(current_due - amount, 2)
        payment = FinePayment(
            id=str(uuid4()),
            fine_id=fine.id,
            member_id=fine.member_id,
            payment_date=date.today(),
            payment_amount=amount,
            payment_method=payload.payment_method or "physical",
            handled_by=identity_subject(admin),
            notes=payload.notes,
            created_at=now,
        )
        db.add(payment)
        fine.fine_amount = remaining
        fine.payment_method = payment.payment_method
        fine.updated_at = now
        if remaining == 0:
            fine.status = "paid"
            fine.paid_at = now
        payment_result = {
            "appliedAmount": amount,
            "remainingAmount": remaining,
        }

    db.commit()
    db.refresh(fine)
    response: dict[str, Any] = {"data": _serialize_fine(db, fine)}
    if payment_result is not None:
        response["payment"] = payment_result
    return response


@router.delete("/{fine_id}")
def delete_fine(
    fine_id: str,
    _admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
    fine = _find_fine(db, fine_id)
    db.query(FinePayment).filter(FinePayment.fine_id == fine.id).delete(
        synchronize_session=False
    )
    db.delete(fine)
    db.commit()
    return {"success": True}
