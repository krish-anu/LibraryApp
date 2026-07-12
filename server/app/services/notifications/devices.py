from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy.orm import Session

from app.models.notification import DeviceToken

from .repository import session_scope


def register_device_token(
    *,
    user_id: str,
    token: str,
    platform: str,
    db: Session | None = None,
) -> dict[str, Any]:
    with session_scope(db) as session:
        row = session.query(DeviceToken).filter(DeviceToken.token == token).first()
        if row:
            row.user_id = user_id
            row.platform = platform
            row.updated_at = datetime.utcnow()
        else:
            row = DeviceToken(user_id=user_id, token=token, platform=platform)
            session.add(row)
        session.commit()
        session.refresh(row)
        return {
            "id": row.id,
            "user_id": row.user_id,
            "token": row.token,
            "platform": row.platform,
        }


def unregister_device_token(
    *, user_id: str, token: str, db: Session | None = None
) -> bool:
    with session_scope(db) as session:
        deleted = (
            session.query(DeviceToken)
            .filter(DeviceToken.user_id == user_id, DeviceToken.token == token)
            .delete(synchronize_session=False)
        )
        session.commit()
        return bool(deleted)


def list_device_tokens_for_user(
    user_id: str, *, db: Session | None = None
) -> list[str]:
    with session_scope(db) as session:
        rows = session.query(DeviceToken.token).filter(DeviceToken.user_id == user_id)
        return [str(token) for (token,) in rows.all()]
