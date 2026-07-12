from __future__ import annotations

from typing import Any


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
