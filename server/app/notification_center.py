from __future__ import annotations

from typing import Any


class NotificationMigrationError(RuntimeError):
    pass


def _unavailable(operation: str) -> None:
    raise NotificationMigrationError(
        f"{operation} is not available until notifications are migrated to PostgreSQL."
    )


def list_notifications(
    recipient_type: str,
    recipient_id: str | None = None,
    *,
    limit: int = 50,
) -> list[dict[str, Any]]:
    _unavailable("Listing notifications")


def unread_notification_count(
    recipient_type: str,
    recipient_id: str | None = None,
) -> int:
    _unavailable("Counting unread notifications")


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
) -> dict[str, Any]:
    _unavailable("Creating notifications")


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
    _unavailable("Creating user notifications")


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
    _unavailable("Creating admin notifications")


def mark_notification_read(
    notification_id: str,
    recipient_type: str,
    recipient_id: str | None = None,
) -> dict[str, Any]:
    _unavailable("Marking notifications read")


def mark_all_notifications_read(
    recipient_type: str,
    recipient_id: str | None = None,
) -> int:
    _unavailable("Marking all notifications read")


def register_device_token(
    *,
    user_id: str,
    token: str,
    platform: str,
) -> dict[str, Any]:
    _unavailable("Registering notification device tokens")


def unregister_device_token(*, user_id: str, token: str) -> bool:
    _unavailable("Unregistering notification device tokens")


def list_device_tokens_for_user(user_id: str) -> list[str]:
    _unavailable("Listing notification device tokens")


def send_push_notification_to_user(
    user_id: str,
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> None:
    _unavailable("Sending push notifications")
