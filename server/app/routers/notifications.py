from __future__ import annotations

from datetime import date
from typing import Any, cast

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..dependencies import get_db, verify_access_token
from ..models import book as book_model
from ..models import loan as loan_model
from ..models import settings as settings_model
from ..notification_center import (
    list_notifications,
    mark_all_notifications_read,
    mark_notification_read,
    register_device_token,
    unread_notification_count,
    unregister_device_token,
    create_user_notification,
)
from ..pydantic_schemas.notification import (
    DeviceTokenPayload,
    Notification,
    NotificationCount,
    NotificationReadResult,
)
from ..router_utils import raise_store_http_error

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _recipient_id(identity: dict[str, Any]) -> str:
    sub = str(identity.get("sub") or "").strip()
    if not sub:
        raise ValueError("Authenticated user is missing subject")
    return sub


def _settings_row(db: Session) -> Any | None:
    return (
        db.query(settings_model.Settings)
        .order_by(settings_model.Settings.created_at.asc())
        .first()
    )


def _sync_due_notifications_for_user(db: Session, user_id: str) -> None:
    settings_row = _settings_row(db)
    send_notifications = (
        bool(getattr(settings_row, "send_notifications", True))
        if settings_row is not None
        else True
    )
    if not send_notifications:
        return

    notify_days = (
        int(getattr(settings_row, "notification_days_before_due", 3))
        if settings_row is not None
        else 3
    )
    today = date.today()
    loans = (
        db.query(loan_model.Loan)
        .filter(loan_model.Loan.member_id == user_id)
        .all()
    )

    for loan in loans:
        due_date = cast(date | None, loan.returned_date)
        if due_date is None:
            continue
        days_remaining = (due_date - today).days
        book = (
            db.query(book_model.Book)
            .filter(book_model.Book.id == loan.book_id)
            .first()
        )
        book_title = str(getattr(book, "title", "your borrowed book") or "your borrowed book")

        if days_remaining == notify_days:
            create_user_notification(
                user_id,
                title="Book due soon",
                body=(
                    f'"{book_title}" is due in {notify_days} day'
                    f'{"s" if notify_days != 1 else ""} on {due_date.isoformat()}.'
                ),
                category="due_soon",
                entity_type="loan",
                entity_id=str(loan.id),
                metadata={
                    "book_id": str(loan.book_id),
                    "book_title": book_title,
                    "due_date": due_date.isoformat(),
                    "days_remaining": days_remaining,
                },
                dedupe_key=f"due-soon:{loan.id}:{due_date.isoformat()}",
                send_push=True,
            )
        elif days_remaining < 0:
            create_user_notification(
                user_id,
                title="Book overdue",
                body=(
                    f'"{book_title}" was due on {due_date.isoformat()}. '
                    "Please return or renew it as soon as possible."
                ),
                category="overdue",
                entity_type="loan",
                entity_id=str(loan.id),
                metadata={
                    "book_id": str(loan.book_id),
                    "book_title": book_title,
                    "due_date": due_date.isoformat(),
                    "days_overdue": abs(days_remaining),
                },
                dedupe_key=f"overdue:{loan.id}:{due_date.isoformat()}",
                send_push=True,
            )


@router.get("", response_model=list[Notification])
def get_notifications(
    identity: dict[str, Any] = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    try:
        user_id = _recipient_id(identity)
        _sync_due_notifications_for_user(db, user_id)
        return list_notifications("user", user_id, limit=100)
    except Exception as error:
        raise_store_http_error(error)


@router.get("/unread-count", response_model=NotificationCount)
def get_unread_count(identity: dict[str, Any] = Depends(verify_access_token)):
    try:
        user_id = _recipient_id(identity)
        return {"unread": unread_notification_count("user", user_id)}
    except Exception as error:
        raise_store_http_error(error)


@router.post("/{notification_id}/read", response_model=Notification)
def read_notification(
    notification_id: str,
    identity: dict[str, Any] = Depends(verify_access_token),
):
    try:
        user_id = _recipient_id(identity)
        return mark_notification_read(notification_id, "user", user_id)
    except Exception as error:
        raise_store_http_error(error)


@router.post("/read-all", response_model=NotificationReadResult)
def read_all_notifications(identity: dict[str, Any] = Depends(verify_access_token)):
    try:
        user_id = _recipient_id(identity)
        marked = mark_all_notifications_read("user", user_id)
        return {"success": True, "marked": marked}
    except Exception as error:
        raise_store_http_error(error)


@router.post("/device-token")
def upsert_device_token(
    payload: DeviceTokenPayload,
    identity: dict[str, Any] = Depends(verify_access_token),
):
    try:
        user_id = _recipient_id(identity)
        return register_device_token(
            user_id=user_id,
            token=payload.token,
            platform=payload.platform,
        )
    except Exception as error:
        raise_store_http_error(error)


@router.delete("/device-token")
def delete_device_token(
    payload: DeviceTokenPayload,
    identity: dict[str, Any] = Depends(verify_access_token),
):
    try:
        user_id = _recipient_id(identity)
        removed = unregister_device_token(user_id=user_id, token=payload.token)
        return {"success": removed}
    except Exception as error:
        raise_store_http_error(error)
