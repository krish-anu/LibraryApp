from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime
from typing import Any, Iterator

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .database import SessionLocal
from .models.notification import DeviceToken, Notification


class NotificationMigrationError(RuntimeError):
    """Kept for compatibility with older callers of this module."""


@contextmanager
def _session(db: Session | None = None) -> Iterator[Session]:
    if db is not None:
        yield db
        return

    owned = SessionLocal()
    try:
        yield owned
    finally:
        owned.close()


def _notification_dict(row: Notification) -> dict[str, Any]:
    return {
        "id": row.id,
        "title": row.title,
        "body": row.body,
        "category": row.category,
        "recipient_type": row.recipient_type,
        "recipient_id": row.recipient_id,
        "entity_type": row.entity_type,
        "entity_id": row.entity_id,
        "metadata": row.metadata_json or {},
        "read": bool(row.read),
        "read_at": row.read_at,
        "created_at": row.created_at,
        "updated_at": row.updated_at,
    }


def _recipient_query(
    db: Session,
    recipient_type: str,
    recipient_id: str | None,
) -> Any:
    query = db.query(Notification).filter(
        Notification.recipient_type == recipient_type
    )
    if recipient_type == "admin":
        return query.filter(Notification.recipient_id.is_(None))
    return query.filter(Notification.recipient_id == recipient_id)


def list_notifications(
    recipient_type: str,
    recipient_id: str | None = None,
    *,
    limit: int = 50,
    db: Session | None = None,
) -> list[dict[str, Any]]:
    with _session(db) as session:
        rows = (
            _recipient_query(session, recipient_type, recipient_id)
            .order_by(Notification.created_at.desc())
            .limit(max(1, min(limit, 100)))
            .all()
        )
        return [_notification_dict(row) for row in rows]


def unread_notification_count(
    recipient_type: str,
    recipient_id: str | None = None,
    *,
    db: Session | None = None,
) -> int:
    with _session(db) as session:
        return int(
            _recipient_query(session, recipient_type, recipient_id)
            .filter(Notification.read.is_(False))
            .count()
        )


def create_notification(
    *,
    recipient_type: str,
    recipient_id: str | None = None,
    title: str,
    body: str,
    category: str,
    entity_type: str | None = None,
    entity_id: str | None = None,
    metadata: dict[str, Any] | None = None,
    dedupe_key: str | None = None,
    send_push: bool = False,
    push_data: dict[str, Any] | None = None,
    db: Session | None = None,
) -> dict[str, Any]:
    with _session(db) as session:
        if dedupe_key:
            existing = (
                session.query(Notification)
                .filter(Notification.dedupe_key == dedupe_key)
                .first()
            )
            if existing:
                return _notification_dict(existing)

        row = Notification(
            recipient_type=recipient_type,
            recipient_id=recipient_id,
            title=title,
            body=body,
            category=category,
            entity_type=entity_type,
            entity_id=entity_id,
            metadata_json=metadata or {},
            dedupe_key=dedupe_key,
        )
        session.add(row)
        try:
            session.commit()
        except IntegrityError:
            session.rollback()
            if dedupe_key:
                existing = (
                    session.query(Notification)
                    .filter(Notification.dedupe_key == dedupe_key)
                    .first()
                )
                if existing:
                    return _notification_dict(existing)
            raise
        session.refresh(row)

        if send_push and recipient_type == "user" and recipient_id:
            send_push_notification_to_user(
                recipient_id,
                title=title,
                body=body,
                data=push_data,
            )
        return _notification_dict(row)


def create_user_notification(
    user_id: str,
    *,
    title: str,
    body: str,
    category: str,
    entity_type: str | None = None,
    entity_id: str | None = None,
    metadata: dict[str, Any] | None = None,
    dedupe_key: str | None = None,
    send_push: bool = True,
    push_data: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return create_notification(
        recipient_type="user",
        recipient_id=user_id,
        title=title,
        body=body,
        category=category,
        entity_type=entity_type,
        entity_id=entity_id,
        metadata=metadata,
        dedupe_key=dedupe_key,
        send_push=send_push,
        push_data=push_data,
    )


def create_admin_notification(
    *,
    title: str,
    body: str,
    category: str,
    entity_type: str | None = None,
    entity_id: str | None = None,
    metadata: dict[str, Any] | None = None,
    dedupe_key: str | None = None,
) -> dict[str, Any]:
    return create_notification(
        recipient_type="admin",
        title=title,
        body=body,
        category=category,
        entity_type=entity_type,
        entity_id=entity_id,
        metadata=metadata,
        dedupe_key=dedupe_key,
    )


def mark_notification_read(
    notification_id: str,
    recipient_type: str,
    recipient_id: str | None = None,
    *,
    db: Session | None = None,
) -> dict[str, Any] | None:
    with _session(db) as session:
        row = (
            _recipient_query(session, recipient_type, recipient_id)
            .filter(Notification.id == notification_id)
            .first()
        )
        if not row:
            return None
        if not row.read:
            row.read = True
            row.read_at = datetime.utcnow()
            row.updated_at = datetime.utcnow()
            session.commit()
            session.refresh(row)
        return _notification_dict(row)


def mark_all_notifications_read(
    recipient_type: str,
    recipient_id: str | None = None,
    *,
    db: Session | None = None,
) -> int:
    with _session(db) as session:
        now = datetime.utcnow()
        marked = (
            _recipient_query(session, recipient_type, recipient_id)
            .filter(Notification.read.is_(False))
            .update(
                {
                    Notification.read: True,
                    Notification.read_at: now,
                    Notification.updated_at: now,
                },
                synchronize_session=False,
            )
        )
        session.commit()
        return int(marked)


def register_device_token(
    *,
    user_id: str,
    token: str,
    platform: str,
    db: Session | None = None,
) -> dict[str, Any]:
    with _session(db) as session:
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
    with _session(db) as session:
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
    with _session(db) as session:
        rows = session.query(DeviceToken.token).filter(DeviceToken.user_id == user_id)
        return [str(token) for (token,) in rows.all()]


def send_push_notification_to_user(
    user_id: str,
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> None:
    # Push transport is optional. Notifications remain available in-app even when
    # no Firebase/APNs provider has been configured.
    return None
