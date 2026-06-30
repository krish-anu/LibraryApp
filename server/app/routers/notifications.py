from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from ..dependencies import (
    get_db,
    identity_is_admin,
    identity_subject,
    verify_access_token,
)
from ..notification_center import (
    list_notifications,
    mark_all_notifications_read,
    mark_notification_read,
    register_device_token,
    unregister_device_token,
    unread_notification_count,
)
from ..pydantic_schemas.notification import (
    DeviceTokenPayload,
    Notification,
    NotificationCount,
    NotificationReadResult,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _recipient(identity: dict[str, Any]) -> tuple[str, str | None]:
    if identity_is_admin(identity):
        return "admin", None
    return "user", identity_subject(identity)


@router.get("", response_model=list[Notification])
def get_notifications(
    limit: int = Query(default=50, ge=1, le=100),
    identity: dict[str, Any] = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    recipient_type, recipient_id = _recipient(identity)
    return list_notifications(recipient_type, recipient_id, limit=limit, db=db)


@router.get("/unread-count", response_model=NotificationCount)
def get_unread_count(
    identity: dict[str, Any] = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    recipient_type, recipient_id = _recipient(identity)
    return {
        "unread": unread_notification_count(
            recipient_type, recipient_id, db=db
        )
    }


@router.post("/read-all", response_model=NotificationReadResult)
def read_all_notifications(
    identity: dict[str, Any] = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    recipient_type, recipient_id = _recipient(identity)
    return {
        "success": True,
        "marked": mark_all_notifications_read(
            recipient_type, recipient_id, db=db
        ),
    }


@router.post("/device-token")
def upsert_device_token(
    payload: DeviceTokenPayload,
    identity: dict[str, Any] = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    return register_device_token(
        user_id=identity_subject(identity),
        token=payload.token,
        platform=payload.platform,
        db=db,
    )


@router.delete("/device-token", response_model=NotificationReadResult)
def delete_device_token(
    payload: DeviceTokenPayload,
    identity: dict[str, Any] = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    deleted = unregister_device_token(
        user_id=identity_subject(identity), token=payload.token, db=db
    )
    return {"success": True, "marked": int(deleted)}


@router.post("/{notification_id}/read", response_model=Notification)
def read_notification(
    notification_id: str,
    identity: dict[str, Any] = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    recipient_type, recipient_id = _recipient(identity)
    notification = mark_notification_read(
        notification_id, recipient_type, recipient_id, db=db
    )
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notification
