from __future__ import annotations

from datetime import datetime
from uuid import uuid4

from sqlalchemy import Boolean, DateTime, JSON, TEXT
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid4()))
    title: Mapped[str] = mapped_column(TEXT, nullable=False)
    body: Mapped[str] = mapped_column(TEXT, nullable=False)
    category: Mapped[str] = mapped_column(TEXT, nullable=False)
    recipient_type: Mapped[str] = mapped_column(TEXT, nullable=False, index=True)
    recipient_id: Mapped[str | None] = mapped_column(TEXT, nullable=True, index=True)
    entity_type: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    entity_id: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    metadata_json: Mapped[dict] = mapped_column(
        "metadata", JSON, nullable=False, default=dict
    )
    dedupe_key: Mapped[str | None] = mapped_column(
        TEXT, nullable=True, unique=True, index=True
    )
    read: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, index=True)
    read_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, default=datetime.utcnow, index=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(TEXT, nullable=False, index=True)
    token: Mapped[str] = mapped_column(TEXT, nullable=False, unique=True, index=True)
    platform: Mapped[str] = mapped_column(TEXT, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )
