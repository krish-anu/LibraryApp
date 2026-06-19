from __future__ import annotations

from datetime import date
from typing import Any, cast

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..dependencies import get_db, verify_access_token
from ..notification_center import NotificationMigrationError
from ..pydantic_schemas.notification import Notification

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _recipient_id(identity: dict[str, Any]) -> str:
    sub = str(identity.get("sub") or "").strip()
    if not sub:
        raise ValueError("Authenticated user is missing subject")
    return sub


@router.get("", response_model=list[Notification])
def get_notifications(
    identity: dict[str, Any] = Depends(verify_access_token),
):
    raise HTTPException(
        status_code=501,
        detail="Notifications are not migrated to PostgreSQL yet.",
    )


@router.get("/unread-count")
def get_unread_count(identity: dict[str, Any] = Depends(verify_access_token)):
    raise HTTPException(
        status_code=501,
        detail="Notifications are not migrated to PostgreSQL yet.",
    )


@router.post("/{notification_id}/read", response_model=Notification)
def read_notification(
    notification_id: str,
    identity: dict[str, Any] = Depends(verify_access_token),
):
    raise HTTPException(
        status_code=501,
        detail="Notifications are not migrated to PostgreSQL yet.",
    )


@router.post("/read-all")
def read_all_notifications(identity: dict[str, Any] = Depends(verify_access_token)):
    raise HTTPException(
        status_code=501,
        detail="Notifications are not migrated to PostgreSQL yet.",
    )


@router.post("/device-token")
def upsert_device_token(
    identity: dict[str, Any] = Depends(verify_access_token),
):
    raise HTTPException(
        status_code=501,
        detail="Notifications are not migrated to PostgreSQL yet.",
    )


@router.delete("/device-token")
def delete_device_token(
    identity: dict[str, Any] = Depends(verify_access_token),
):
    raise HTTPException(
        status_code=501,
        detail="Notifications are not migrated to PostgreSQL yet.",
    )
