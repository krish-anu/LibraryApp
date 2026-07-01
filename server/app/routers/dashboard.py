from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from ..dependencies import get_db, require_admin
from ..models.book import Book
from ..models.fine import Fine
from ..models.loan import Loan
from ..models.users import User

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


def _month_start(value: date) -> date:
    return value.replace(day=1)


def _previous_month_start(value: date) -> date:
    if value.month == 1:
        return date(value.year - 1, 12, 1)
    return date(value.year, value.month - 1, 1)


def _growth(current: int, previous: int) -> float:
    if previous == 0:
        return 100.0 if current > 0 else 0.0
    return round(((current - previous) / previous) * 100, 1)


@router.get("")
def get_dashboard(
    _admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
    today = date.today()
    current_month = _month_start(today)
    previous_month = _previous_month_start(today)

    active_users = int(db.query(func.count(User.id)).scalar() or 0)
    total_inventory = int(
        db.query(func.coalesce(func.sum(Book.copies_owned), 0)).scalar() or 0
    )

    unpaid_filter = func.lower(func.coalesce(Fine.status, "unpaid")) == "unpaid"
    pending_fines = float(
        db.query(func.coalesce(func.sum(Fine.fine_amount), 0))
        .filter(unpaid_filter)
        .scalar()
        or 0
    )
    fine_count = int(
        db.query(func.count(Fine.id)).filter(unpaid_filter).scalar() or 0
    )

    loan_periods = [
        (returned_date - loan_date).days
        for loan_date, returned_date in db.query(
            Loan.loan_date, Loan.returned_date
        ).all()
        if loan_date is not None and returned_date is not None
    ]
    average_checkout_time = (
        round(sum(loan_periods) / len(loan_periods), 1) if loan_periods else 0
    )

    current_users = int(
        db.query(func.count(User.id))
        .filter(User.created_at >= datetime.combine(current_month, datetime.min.time()))
        .scalar()
        or 0
    )
    previous_users = int(
        db.query(func.count(User.id))
        .filter(
            User.created_at
            >= datetime.combine(previous_month, datetime.min.time()),
            User.created_at
            < datetime.combine(current_month, datetime.min.time()),
        )
        .scalar()
        or 0
    )

    top_book_rows = (
        db.query(Book.id, Book.title, func.count(Loan.id).label("borrow_count"))
        .join(Loan, Loan.book_id == Book.id)
        .group_by(Book.id, Book.title)
        .order_by(func.count(Loan.id).desc(), Book.title.asc())
        .limit(5)
        .all()
    )

    seven_days_start = today - timedelta(days=6)
    borrowed_rows = (
        db.query(Loan.loan_date, func.count(Loan.id).label("borrow_count"))
        .filter(
            Loan.loan_date >= seven_days_start,
            Loan.loan_date <= today,
        )
        .group_by(Loan.loan_date)
        .all()
    )
    borrowed_counts = {
        loan_date: int(count or 0)
        for loan_date, count in borrowed_rows
        if loan_date is not None
    }
    last_7_days = [
        seven_days_start + timedelta(days=offset)
        for offset in range(7)
    ]
    borrowed_last_7_days = [
        {
            "date": day.isoformat(),
            "count": borrowed_counts.get(day, 0),
        }
        for day in last_7_days
    ]

    recent_fine_rows = (
        db.query(Fine, User)
        .outerjoin(User, User.id == Fine.member_id)
        .order_by(Fine.created_at.desc(), Fine.fine_date.desc())
        .limit(5)
        .all()
    )
    recent_fines: list[dict[str, Any]] = []
    for fine, user in recent_fine_rows:
        created_at = fine.created_at
        if created_at is None and fine.fine_date is not None:
            created_at = datetime.combine(fine.fine_date, datetime.min.time())
        recent_fines.append(
            {
                "id": str(fine.id),
                "amount": float(fine.fine_amount or 0),
                "reason": fine.reason or "Library fine",
                "status": fine.status or "unpaid",
                "created_at": created_at,
                "users": (
                    {"id": str(user.id), "name": user.name or "Unknown User"}
                    if user
                    else None
                ),
            }
        )

    return {
        "stats": {
            "activeUsers": active_users,
            "totalInventory": total_inventory,
            "pendingFines": pending_fines,
            "avgCheckoutTime": average_checkout_time,
            "userGrowth": _growth(current_users, previous_users),
            # Books currently have no creation timestamp, so a reliable monthly
            # inventory delta cannot be calculated yet.
            "inventoryGrowth": 0,
            "fineCount": fine_count,
            "checkoutImprovement": 0,
        },
        "topBooks": [
            {"id": str(book_id), "title": title, "count": int(count)}
            for book_id, title, count in top_book_rows
        ],
        "borrowedLast7Days": borrowed_last_7_days,
        "recentFines": recent_fines,
    }
