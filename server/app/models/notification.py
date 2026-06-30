from __future__ import annotations

from datetime import datetime
from uuid import uuid4

from sqlalchemy import Boolean, Column, DateTime, JSON, TEXT

from .base import Base


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(TEXT, primary_key=True, default=lambda: str(uuid4()))
    title = Column(TEXT, nullable=False)
    body = Column(TEXT, nullable=False)
    category = Column(TEXT, nullable=False)
    recipient_type = Column(TEXT, nullable=False, index=True)
    recipient_id = Column(TEXT, nullable=True, index=True)
    entity_type = Column(TEXT, nullable=True)
    entity_id = Column(TEXT, nullable=True)
    metadata_json = Column("metadata", JSON, nullable=False, default=dict)
    dedupe_key = Column(TEXT, nullable=True, unique=True, index=True)
    read = Column(Boolean, nullable=False, default=False, index=True)
    read_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow, index=True)
    updated_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id = Column(TEXT, primary_key=True, default=lambda: str(uuid4()))
    user_id = Column(TEXT, nullable=False, index=True)
    token = Column(TEXT, nullable=False, unique=True, index=True)
    platform = Column(TEXT, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )
