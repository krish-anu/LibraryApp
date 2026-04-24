from __future__ import annotations

import hashlib
from typing import Any

from .firestore_store import (
    ConfigurationError,
    NotFoundError,
    get_firestore_client,
    make_id,
    now_iso,
)


NOTIFICATIONS_COLLECTION = "notifications"
DEVICE_TOKENS_COLLECTION = "notificationDevices"


def _recipient_key(recipient_type: str, recipient_id: str | None = None) -> str:
    normalized_type = recipient_type.strip().lower()
    normalized_id = (recipient_id or "").strip()
    return f"{normalized_type}:{normalized_id or 'all'}"


def _normalize_push_data(data: dict[str, Any] | None) -> dict[str, str]:
    if not data:
        return {}
    normalized: dict[str, str] = {}
    for key, value in data.items():
        if value is None:
            continue
        normalized[str(key)] = str(value)
    return normalized


def _ensure_firebase_app():
    try:
        get_firestore_client()
        import firebase_admin

        return firebase_admin.get_app()
    except Exception as exc:  # pragma: no cover - defensive wrapper
        raise ConfigurationError(str(exc)) from exc


def _stream_collection_by_field(
    collection_name: str,
    field_name: str,
    value: str,
) -> list[dict[str, Any]]:
    client = get_firestore_client()
    docs = client.collection(collection_name).where(field_name, "==", value).stream()
    return [{**(doc.to_dict() or {}), "id": doc.id} for doc in docs]


def notification_exists(dedupe_key: str) -> bool:
    if not dedupe_key.strip():
        return False
    docs = _stream_collection_by_field(
        NOTIFICATIONS_COLLECTION,
        "dedupe_key",
        dedupe_key.strip(),
    )
    return len(docs) > 0


def list_notifications(
    recipient_type: str,
    recipient_id: str | None = None,
    *,
    limit: int = 50,
) -> list[dict[str, Any]]:
    recipient_key = _recipient_key(recipient_type, recipient_id)
    docs = _stream_collection_by_field(
        NOTIFICATIONS_COLLECTION,
        "recipient_key",
        recipient_key,
    )
    docs.sort(key=lambda item: str(item.get("created_at") or ""), reverse=True)
    return docs[: max(1, min(limit, 100))]


def unread_notification_count(
    recipient_type: str,
    recipient_id: str | None = None,
) -> int:
    docs = list_notifications(recipient_type, recipient_id, limit=100)
    return sum(1 for doc in docs if not bool(doc.get("read")))


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
    normalized_dedupe = (dedupe_key or "").strip()
    if normalized_dedupe and notification_exists(normalized_dedupe):
        existing = _stream_collection_by_field(
            NOTIFICATIONS_COLLECTION,
            "dedupe_key",
            normalized_dedupe,
        )
        return existing[0] if existing else {}

    now = now_iso()
    notification_id = make_id("ntf_")
    document = {
        "id": notification_id,
        "recipient_type": recipient_type.strip().lower(),
        "recipient_id": (recipient_id or "").strip() or None,
        "recipient_key": _recipient_key(recipient_type, recipient_id),
        "title": title.strip(),
        "body": body.strip(),
        "category": category.strip(),
        "entity_type": (entity_type or "").strip() or None,
        "entity_id": (entity_id or "").strip() or None,
        "metadata": metadata or {},
        "dedupe_key": normalized_dedupe or None,
        "read": False,
        "read_at": None,
        "created_at": now,
        "updated_at": now,
    }

    client = get_firestore_client()
    client.collection(NOTIFICATIONS_COLLECTION).document(notification_id).set(document)

    if send_push and document["recipient_type"] == "user" and document["recipient_id"]:
        send_push_notification_to_user(
            document["recipient_id"],
            title=document["title"],
            body=document["body"],
            data={
                "notification_id": notification_id,
                "category": document["category"],
                "entity_type": document["entity_type"] or "",
                "entity_id": document["entity_id"] or "",
                **(push_data or {}),
            },
        )

    return document


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
        send_push=False,
    )


def mark_notification_read(
    notification_id: str,
    recipient_type: str,
    recipient_id: str | None = None,
) -> dict[str, Any]:
    client = get_firestore_client()
    ref = client.collection(NOTIFICATIONS_COLLECTION).document(notification_id)
    snapshot = ref.get()
    if not snapshot.exists:
        raise NotFoundError("Notification not found")

    data = snapshot.to_dict() or {}
    expected_key = _recipient_key(recipient_type, recipient_id)
    if str(data.get("recipient_key") or "") != expected_key:
        raise NotFoundError("Notification not found")

    updated = {
        "read": True,
        "read_at": now_iso(),
        "updated_at": now_iso(),
    }
    ref.set(updated, merge=True)
    return {**data, **updated, "id": snapshot.id}


def mark_all_notifications_read(
    recipient_type: str,
    recipient_id: str | None = None,
) -> int:
    client = get_firestore_client()
    docs = list_notifications(recipient_type, recipient_id, limit=100)
    marked = 0
    for doc in docs:
        if bool(doc.get("read")):
            continue
        client.collection(NOTIFICATIONS_COLLECTION).document(str(doc["id"])).set(
            {
                "read": True,
                "read_at": now_iso(),
                "updated_at": now_iso(),
            },
            merge=True,
        )
        marked += 1
    return marked


def register_device_token(
    *,
    user_id: str,
    token: str,
    platform: str,
) -> dict[str, Any]:
    cleaned_user_id = user_id.strip()
    cleaned_token = token.strip()
    cleaned_platform = platform.strip().lower() or "unknown"
    token_hash = hashlib.sha256(cleaned_token.encode()).hexdigest()
    token_id = f"dev_{token_hash[:20]}"
    now = now_iso()
    document = {
        "id": token_id,
        "user_id": cleaned_user_id,
        "token": cleaned_token,
        "platform": cleaned_platform,
        "created_at": now,
        "updated_at": now,
        "last_seen_at": now,
    }
    client = get_firestore_client()
    ref = client.collection(DEVICE_TOKENS_COLLECTION).document(token_id)
    existing = ref.get()
    if existing.exists:
        document["created_at"] = (existing.to_dict() or {}).get("created_at") or now
    ref.set(document, merge=True)
    return document


def unregister_device_token(*, user_id: str, token: str) -> bool:
    cleaned_token = token.strip()
    token_hash = hashlib.sha256(cleaned_token.encode()).hexdigest()
    token_id = f"dev_{token_hash[:20]}"
    client = get_firestore_client()
    ref = client.collection(DEVICE_TOKENS_COLLECTION).document(token_id)
    existing = ref.get()
    if not existing.exists:
        return False
    data = existing.to_dict() or {}
    if user_id.strip() and str(data.get("user_id") or "").strip() != user_id.strip():
        return False
    ref.delete()
    return True


def list_device_tokens_for_user(user_id: str) -> list[str]:
    docs = _stream_collection_by_field(
        DEVICE_TOKENS_COLLECTION,
        "user_id",
        user_id.strip(),
    )
    return [
        str(doc.get("token") or "").strip()
        for doc in docs
        if str(doc.get("token") or "").strip()
    ]


def send_push_notification_to_user(
    user_id: str,
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> None:
    tokens = list_device_tokens_for_user(user_id)
    if not tokens:
        return

    firebase_app = _ensure_firebase_app()
    normalized_data = _normalize_push_data(data)
    invalid_tokens: list[str] = []

    from firebase_admin import messaging

    for token in tokens:
        try:
            message = messaging.Message(
                token=token,
                notification=messaging.Notification(title=title, body=body),
                data=normalized_data,
                android=messaging.AndroidConfig(priority="high"),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(sound="default"),
                    )
                ),
            )
            messaging.send(message, app=firebase_app)
        except Exception:
            invalid_tokens.append(token)

    for token in invalid_tokens:
        unregister_device_token(user_id=user_id, token=token)
