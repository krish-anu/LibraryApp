from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class Notification(BaseModel):
    id: str
    title: str
    body: str
    category: str
    recipient_type: str
    recipient_id: str | None = None
    entity_type: str | None = None
    entity_id: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    read: bool = False
    read_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class NotificationCount(BaseModel):
    unread: int


class NotificationReadResult(BaseModel):
    success: bool = True
    marked: int = 0


class DeviceTokenPayload(BaseModel):
    token: str = Field(min_length=1)
    platform: str = Field(min_length=1)
