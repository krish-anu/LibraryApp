from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime
from typing import Any, Iterator

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import SessionLocal
from app.models.notification import Notification

from .push import send_push_notification_to_user


@contextmanager
def session_scope(db: Session | None = None) -> Iterator[Session]:
    if db is not None:
        yield db
        return

    owned = SessionLocal()
    try:
        yield owned
    finally:
        owned.close()


def notification_dict(row: Notification) -> dict[str, Any]:
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


def recipient_query(
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
    with session_scope(db) as session:
        rows = (
            recipient_query(session, recipient_type, recipient_id)
            .order_by(Notification.created_at.desc())
            .limit(max(1, min(limit, 100)))
            .all()
        )
        return [notification_dict(row) for row in rows]


def unread_notification_count(
    recipient_type: str,
    recipient_id: str | None = None,
    *,
    db: Session | None = None,
) -> int:
    with session_scope(db) as session:
        return int(
            recipient_query(session, recipient_type, recipient_id)
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
    with session_scope(db) as session:
        if dedupe_key:
            existing = (
                session.query(Notification)
                .filter(Notification.dedupe_key == dedupe_key)
                .first()
            )
            if existing:
                return notification_dict(existing)

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
                    return notification_dict(existing)
            raise
        session.refresh(row)

        if send_push and recipient_type == "user" and recipient_id:
            send_push_notification_to_user(
                recipient_id,
                title=title,
                body=body,
                data=push_data,
            )
        return notification_dict(row)


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
    with session_scope(db) as session:
        row = (
            recipient_query(session, recipient_type, recipient_id)
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
        return notification_dict(row)


def mark_all_notifications_read(
    recipient_type: str,
    recipient_id: str | None = None,
    *,
    db: Session | None = None,
) -> int:
    with session_scope(db) as session:
        now = datetime.utcnow()
        marked = (
            recipient_query(session, recipient_type, recipient_id)
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
