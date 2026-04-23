from __future__ import annotations

import json
import os
import uuid
from copy import deepcopy
from datetime import date, datetime, timedelta, timezone
from typing import Any


COLLECTIONS = {
    "books": "books",
    "categories": "categories",
    "fine_payments": "finePayments",
    "fines": "fines",
    "interactions": "interactions",
    "loans": "loans",
    "reservations": "reservations",
    "settings": "settings",
    "users": "users",
}

SETTINGS_DOC_ID = "library"

DEFAULT_SETTINGS = {
    "loan_period_days": 14,
    "max_books_per_user": 5,
    "grace_period_days": 2,
    "daily_fine_rate": 0.50,
    "max_fine_cap": 25.00,
    "block_on_unpaid_fines": True,
    "fine_threshold": 10.00,
    "send_notifications": True,
    "notification_days_before_due": 3,
}

DEFAULT_CATEGORIES = [
    {"id": "cat-fiction", "name": "Fiction"},
    {"id": "cat-non-fiction", "name": "Non-Fiction"},
    {"id": "cat-science-fiction", "name": "Science Fiction"},
    {"id": "cat-mystery", "name": "Mystery"},
    {"id": "cat-romance", "name": "Romance"},
    {"id": "cat-children", "name": "Children"},
    {"id": "cat-reference", "name": "Reference"},
    {"id": "cat-self-help", "name": "Self-Help"},
]

_FIRESTORE_CLIENT: Any | None = None


class StoreError(Exception):
    pass


class ConfigurationError(StoreError):
    pass


class NotFoundError(StoreError):
    pass


class ConflictError(StoreError):
    pass


class ValidationError(StoreError):
    pass


def sanitize_env_value(value: str | None) -> str:
    if not value:
        return ""

    trimmed = value.strip()
    if (
        (trimmed.startswith('"') and trimmed.endswith('"'))
        or (trimmed.startswith("'") and trimmed.endswith("'"))
    ):
        return trimmed[1:-1].strip()
    return trimmed


def parse_service_account_json(raw_value: str) -> dict[str, Any] | None:
    if not raw_value:
        return None

    try:
        return json.loads(raw_value)
    except json.JSONDecodeError as exc:
        raise ConfigurationError(
            f"Invalid FIREBASE_SERVICE_ACCOUNT_JSON value: {exc}"
        ) from exc


def load_service_account_file(path_value: str) -> dict[str, Any] | None:
    path = sanitize_env_value(path_value)
    if not path:
        return None

    try:
        with open(path, encoding="utf-8") as service_account_file:
            return json.load(service_account_file)
    except FileNotFoundError as exc:
        raise ConfigurationError(
            f"Firebase service-account file not found: {path}"
        ) from exc
    except json.JSONDecodeError as exc:
        raise ConfigurationError(
            f"Invalid Firebase service-account JSON file at {path}: {exc}"
        ) from exc


def resolve_firebase_config() -> dict[str, str]:
    service_account = parse_service_account_json(
        sanitize_env_value(os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"))
    )
    service_account = service_account or load_service_account_file(
        os.getenv("FIREBASE_SERVICE_ACCOUNT_FILE")
        or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        or ""
    )
    service_account = service_account or {}

    project_id = (
        sanitize_env_value(os.getenv("FIREBASE_PROJECT_ID"))
        or str(service_account.get("project_id", ""))
    )
    client_email = (
        sanitize_env_value(os.getenv("FIREBASE_CLIENT_EMAIL"))
        or str(service_account.get("client_email", ""))
    )
    private_key = (
        sanitize_env_value(os.getenv("FIREBASE_PRIVATE_KEY"))
        or str(service_account.get("private_key", ""))
    ).replace("\\n", "\n")

    missing: list[str] = []
    if not project_id:
        missing.append("FIREBASE_PROJECT_ID")
    if not client_email:
        missing.append("FIREBASE_CLIENT_EMAIL")
    if not private_key:
        missing.append("FIREBASE_PRIVATE_KEY")

    if missing:
        raise ConfigurationError(
            "Firebase Admin configuration is incomplete. "
            f"Set {', '.join(missing)} or provide FIREBASE_SERVICE_ACCOUNT_JSON."
        )

    return {
        "project_id": project_id,
        "client_email": client_email,
        "private_key": private_key,
    }


def get_firestore_client():
    global _FIRESTORE_CLIENT
    if _FIRESTORE_CLIENT is not None:
        return _FIRESTORE_CLIENT

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError as exc:
        raise ConfigurationError(
            "firebase-admin is not installed for the server backend. "
            "Add it to the Python environment before using Firestore."
        ) from exc

    config = resolve_firebase_config()

    try:
        app = firebase_admin.get_app()
    except ValueError:
        app = firebase_admin.initialize_app(
            credentials.Certificate(
                {
                    "type": "service_account",
                    "project_id": config["project_id"],
                    "client_email": config["client_email"],
                    "private_key": config["private_key"],
                }
            )
        )

    _FIRESTORE_CLIENT = firestore.client(app=app)
    return _FIRESTORE_CLIENT


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def now_iso() -> str:
    return now_utc().isoformat()


def today_date() -> date:
    return now_utc().date()


def today_iso() -> str:
    return today_date().isoformat()


def make_id(prefix: str) -> str:
    return f"{prefix}{uuid.uuid4().hex[:12]}"


def make_member_id() -> str:
    return f"MEM-{uuid.uuid4().hex[:10].upper()}"


def slugify(value: str) -> str:
    parts = ["".join(ch for ch in chunk.lower() if ch.isalnum()) for chunk in value.split()]
    normalized = "-".join(part for part in parts if part)
    return normalized or uuid.uuid4().hex[:8]


def non_empty_string(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    trimmed = value.strip()
    return trimmed or None


def to_int(value: Any, default: int | None = None) -> int | None:
    if value in (None, ""):
        return default
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def to_float(value: Any, default: float | None = None) -> float | None:
    if value in (None, ""):
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def parse_datetime(value: Any, fallback: datetime | None = None) -> datetime | None:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, date):
        return datetime.combine(value, datetime.min.time(), tzinfo=timezone.utc)
    if isinstance(value, str):
        candidate = value.strip()
        if not candidate:
            return fallback
        normalized = candidate.replace("Z", "+00:00")
        try:
            parsed = datetime.fromisoformat(normalized)
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            return fallback
    return fallback


def parse_date_value(value: Any, fallback: date | None = None) -> date | None:
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    parsed = parse_datetime(value)
    if parsed is not None:
        return parsed.date()
    return fallback


def iso_datetime_value(value: Any, fallback: str | None = None) -> str | None:
    parsed = parse_datetime(value)
    if parsed is not None:
        return parsed.astimezone(timezone.utc).isoformat()
    return fallback


def iso_date_value(value: Any, fallback: str | None = None) -> str | None:
    parsed = parse_date_value(value)
    if parsed is not None:
        return parsed.isoformat()
    return fallback


def active_reservation_status(status: str | None) -> bool:
    normalized = (status or "").strip().lower()
    return normalized not in {"cancelled", "canceled", "expired", "completed", "fulfilled"}


class BaseLibraryStore:
    def _list_documents(self, collection: str) -> list[dict[str, Any]]:
        raise NotImplementedError

    def _get_document(self, collection: str, doc_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    def _set_document(
        self, collection: str, doc_id: str, data: dict[str, Any], merge: bool = False
    ) -> None:
        raise NotImplementedError

    def _delete_document(self, collection: str, doc_id: str) -> None:
        raise NotImplementedError

    def project_id(self) -> str:
        raise NotImplementedError

    def ping(self) -> dict[str, Any]:
        self.get_settings()
        return {
            "status": "ok",
            "backend": "firebase-firestore",
            "project_id": self.project_id(),
        }

    def _ensure_default_categories(self) -> None:
        if self._list_documents(COLLECTIONS["categories"]):
            return
        for category in DEFAULT_CATEGORIES:
            self._set_document(COLLECTIONS["categories"], category["id"], category)

    def _ensure_settings_document(self) -> dict[str, Any]:
        settings = self._get_document(COLLECTIONS["settings"], SETTINGS_DOC_ID)
        if settings is None:
            timestamp = now_iso()
            settings = {
                "id": SETTINGS_DOC_ID,
                **DEFAULT_SETTINGS,
                "created_at": timestamp,
                "updated_at": timestamp,
            }
            self._set_document(COLLECTIONS["settings"], SETTINGS_DOC_ID, settings)
        return settings

    def _category_response(self, category: dict[str, Any]) -> dict[str, Any]:
        return {
            "id": str(category["id"]),
            "name": non_empty_string(category.get("name")) or "Uncategorized",
            "image_url": non_empty_string(category.get("image_url")),
        }

    def _settings_response(self, settings: dict[str, Any]) -> dict[str, Any]:
        return {
            "id": str(settings.get("id") or SETTINGS_DOC_ID),
            "loan_period_days": max(
                1, to_int(settings.get("loan_period_days"), DEFAULT_SETTINGS["loan_period_days"]) or 14
            ),
            "max_books_per_user": max(
                1,
                to_int(
                    settings.get("max_books_per_user"),
                    DEFAULT_SETTINGS["max_books_per_user"],
                )
                or 5,
            ),
            "grace_period_days": max(
                0,
                to_int(
                    settings.get("grace_period_days"),
                    DEFAULT_SETTINGS["grace_period_days"],
                )
                or 0,
            ),
            "daily_fine_rate": max(
                0.0,
                to_float(
                    settings.get("daily_fine_rate"),
                    DEFAULT_SETTINGS["daily_fine_rate"],
                )
                or 0.0,
            ),
            "max_fine_cap": max(
                0.0,
                to_float(settings.get("max_fine_cap"), DEFAULT_SETTINGS["max_fine_cap"])
                or 0.0,
            ),
            "block_on_unpaid_fines": bool(
                settings.get(
                    "block_on_unpaid_fines",
                    DEFAULT_SETTINGS["block_on_unpaid_fines"],
                )
            ),
            "fine_threshold": max(
                0.0,
                to_float(settings.get("fine_threshold"), DEFAULT_SETTINGS["fine_threshold"])
                or 0.0,
            ),
            "send_notifications": bool(
                settings.get("send_notifications", DEFAULT_SETTINGS["send_notifications"])
            ),
            "notification_days_before_due": max(
                0,
                to_int(
                    settings.get(
                        "notification_days_before_due",
                        DEFAULT_SETTINGS["notification_days_before_due"],
                    ),
                    DEFAULT_SETTINGS["notification_days_before_due"],
                )
                or 0,
            ),
            "created_at": parse_datetime(settings.get("created_at"), now_utc()),
            "updated_at": parse_datetime(settings.get("updated_at"), now_utc()),
        }

    def _find_category_by_name(self, name: str) -> dict[str, Any] | None:
        normalized_name = name.strip().lower()
        for category in self._list_documents(COLLECTIONS["categories"]):
            if (non_empty_string(category.get("name")) or "").lower() == normalized_name:
                return category
        return None

    def _ensure_category(self, name: str) -> dict[str, Any]:
        self._ensure_default_categories()
        existing = self._find_category_by_name(name)
        if existing is not None:
            return existing

        category_id = f"cat-{slugify(name)}"
        candidate = {"id": category_id, "name": name, "image_url": None}
        self._set_document(COLLECTIONS["categories"], category_id, candidate)
        return candidate

    def _book_response(
        self, book: dict[str, Any], categories_by_id: dict[str, dict[str, Any]] | None = None
    ) -> dict[str, Any]:
        category_id = non_empty_string(book.get("category_id"))
        category_name = non_empty_string(book.get("category"))
        if category_id and categories_by_id:
            category_name = self._category_response(categories_by_id.get(category_id, {"id": category_id})).get(
                "name"
            )

        return {
            "id": str(book["id"]),
            "title": non_empty_string(book.get("title")) or "",
            "author": non_empty_string(book.get("author")) or "",
            "category": category_name or "Uncategorized",
            "description": non_empty_string(book.get("description")) or "",
            "rating": to_float(book.get("rating"), 0.0) or 0.0,
            "publication_year": to_int(book.get("publication_year"), 0) or 0,
            "copies_owned": max(0, to_int(book.get("copies_owned"), 0) or 0),
            "image": non_empty_string(book.get("image")) or "",
            "language": non_empty_string(book.get("language")) or "English",
            "pages": max(1, to_int(book.get("pages"), 200) or 200),
            "rating_count": max(0, to_int(book.get("rating_count"), 0) or 0),
        }

    def _user_response(self, user: dict[str, Any]) -> dict[str, Any]:
        return {
            "id": str(user["id"]),
            "member_id": non_empty_string(user.get("member_id")),
            "name": non_empty_string(user.get("name")),
            "email": non_empty_string(user.get("email")),
            "phone": non_empty_string(user.get("phone")),
            "address": non_empty_string(user.get("address")),
            "profile_image": non_empty_string(user.get("profile_image")),
            "joined_date": parse_date_value(user.get("joined_date"), today_date()),
            "created_at": parse_datetime(user.get("created_at"), now_utc()),
            "updated_at": parse_datetime(user.get("updated_at"), now_utc()),
        }

    def _loan_response(self, loan: dict[str, Any]) -> dict[str, Any]:
        return {
            "id": str(loan["id"]),
            "book_id": str(loan["book_id"]),
            "member_id": str(loan["member_id"]),
            "loan_date": parse_date_value(loan.get("loan_date"), today_date()),
            "returned_date": parse_date_value(loan.get("returned_date")),
        }

    def _reservation_response(self, reservation: dict[str, Any]) -> dict[str, Any]:
        return {
            "id": str(reservation["id"]),
            "book_id": str(reservation["book_id"]),
            "member_id": str(reservation["member_id"]),
            "reservation_date": parse_date_value(reservation.get("reservation_date")),
            "status": non_empty_string(reservation.get("status")),
        }

    def _all_categories_by_id(self) -> dict[str, dict[str, Any]]:
        self._ensure_default_categories()
        return {
            str(category["id"]): category
            for category in self._list_documents(COLLECTIONS["categories"])
        }

    def list_categories(self) -> list[dict[str, Any]]:
        categories = [self._category_response(category) for category in self._all_categories_by_id().values()]
        return sorted(categories, key=lambda category: category["name"].lower())

    def get_category(self, category_id: str) -> dict[str, Any]:
        self._ensure_default_categories()
        category = self._get_document(COLLECTIONS["categories"], category_id)
        if category is None:
            raise NotFoundError("Category not found")
        return self._category_response(category)

    def create_category(self, payload: dict[str, Any]) -> dict[str, Any]:
        name = non_empty_string(payload.get("name"))
        if not name:
            raise ValidationError("Category name is required")
        if self._find_category_by_name(name) is not None:
            raise ConflictError("Category already exists")

        category_id = f"cat-{slugify(name)}"
        category = {
            "id": category_id,
            "name": name,
            "image_url": non_empty_string(payload.get("image_url")),
        }
        self._set_document(COLLECTIONS["categories"], category_id, category)
        return self._category_response(category)

    def update_category(self, category_id: str, payload: dict[str, Any]) -> dict[str, Any]:
        existing = self._get_document(COLLECTIONS["categories"], category_id)
        if existing is None:
            raise NotFoundError("Category not found")

        name = non_empty_string(payload.get("name")) or non_empty_string(existing.get("name"))
        if not name:
            raise ValidationError("Category name is required")

        duplicate = self._find_category_by_name(name)
        if duplicate is not None and str(duplicate["id"]) != category_id:
            raise ConflictError("Category already exists")

        updated = {
            **existing,
            "id": category_id,
            "name": name,
            "image_url": non_empty_string(payload.get("image_url"))
            if "image_url" in payload
            else non_empty_string(existing.get("image_url")),
        }
        self._set_document(COLLECTIONS["categories"], category_id, updated, merge=False)
        return self._category_response(updated)

    def delete_category(self, category_id: str) -> None:
        existing = self._get_document(COLLECTIONS["categories"], category_id)
        if existing is None:
            raise NotFoundError("Category not found")

        for book in self._list_documents(COLLECTIONS["books"]):
            if non_empty_string(book.get("category_id")) == category_id:
                updated = {
                    **book,
                    "category_id": None,
                    "category": "Uncategorized",
                    "updated_at": now_iso(),
                }
                self._set_document(COLLECTIONS["books"], str(book["id"]), updated, merge=False)

        self._delete_document(COLLECTIONS["categories"], category_id)

    def list_books(self) -> list[dict[str, Any]]:
        categories_by_id = self._all_categories_by_id()
        books = [
            self._book_response(book, categories_by_id)
            for book in self._list_documents(COLLECTIONS["books"])
        ]
        return sorted(books, key=lambda book: book["title"].lower())

    def get_book(self, book_id: str) -> dict[str, Any]:
        categories_by_id = self._all_categories_by_id()
        book = self._get_document(COLLECTIONS["books"], book_id)
        if book is None:
            raise NotFoundError("Book not found")
        return self._book_response(book, categories_by_id)

    def create_book(self, payload: dict[str, Any]) -> dict[str, Any]:
        title = non_empty_string(payload.get("title"))
        if not title:
            raise ValidationError("Title is required")

        author = non_empty_string(payload.get("author")) or ""
        category_name = non_empty_string(payload.get("category")) or "Uncategorized"
        category = self._ensure_category(category_name)

        rating = to_float(payload.get("rating"), 0.0) or 0.0
        if rating < 0 or rating > 5:
            raise ValidationError("Rating must be between 0 and 5")

        publication_year = to_int(payload.get("publication_year"), 0) or 0
        copies_owned = to_int(payload.get("copies_owned"), 1)
        if copies_owned is None or copies_owned < 0:
            raise ValidationError("Copies owned must be zero or greater")

        pages = to_int(payload.get("pages"), 200) or 200
        if pages < 1:
            raise ValidationError("Pages must be greater than zero")

        book_id = make_id("book_")
        timestamp = now_iso()
        book = {
            "id": book_id,
            "title": title,
            "author": author,
            "category": category_name,
            "category_id": category["id"],
            "description": non_empty_string(payload.get("description")) or "",
            "rating": rating,
            "publication_year": publication_year,
            "copies_owned": copies_owned,
            "copies_available": copies_owned,
            "image": non_empty_string(payload.get("image")) or "",
            "language": non_empty_string(payload.get("language")) or "English",
            "pages": pages,
            "rating_count": max(0, to_int(payload.get("rating_count"), 0) or 0),
            "created_at": timestamp,
            "updated_at": timestamp,
        }
        self._set_document(COLLECTIONS["books"], book_id, book)
        return self.get_book(book_id)

    def update_book(self, book_id: str, payload: dict[str, Any]) -> dict[str, Any]:
        existing = self._get_document(COLLECTIONS["books"], book_id)
        if existing is None:
            raise NotFoundError("Book not found")

        updated = dict(existing)
        if "title" in payload:
            title = non_empty_string(payload.get("title"))
            if not title:
                raise ValidationError("Title is required")
            updated["title"] = title

        if "author" in payload:
            updated["author"] = non_empty_string(payload.get("author")) or ""

        if "category" in payload:
            category_name = non_empty_string(payload.get("category")) or "Uncategorized"
            category = self._ensure_category(category_name)
            updated["category"] = category_name
            updated["category_id"] = category["id"]

        if "description" in payload:
            updated["description"] = non_empty_string(payload.get("description")) or ""

        if "rating" in payload:
            rating = to_float(payload.get("rating"), 0.0)
            if rating is None or rating < 0 or rating > 5:
                raise ValidationError("Rating must be between 0 and 5")
            updated["rating"] = rating

        if "publication_year" in payload:
            updated["publication_year"] = to_int(payload.get("publication_year"), 0) or 0

        if "copies_owned" in payload:
            copies_owned = to_int(payload.get("copies_owned"))
            if copies_owned is None or copies_owned < 0:
                raise ValidationError("Copies owned must be zero or greater")
            current_available = max(0, to_int(existing.get("copies_available"), copies_owned) or 0)
            current_owned = max(0, to_int(existing.get("copies_owned"), copies_owned) or 0)
            delta = copies_owned - current_owned
            updated["copies_owned"] = copies_owned
            updated["copies_available"] = max(0, current_available + delta)

        if "image" in payload:
            updated["image"] = non_empty_string(payload.get("image")) or ""

        if "language" in payload:
            updated["language"] = non_empty_string(payload.get("language")) or "English"

        if "pages" in payload:
            pages = to_int(payload.get("pages"), 200)
            if pages is None or pages < 1:
                raise ValidationError("Pages must be greater than zero")
            updated["pages"] = pages

        if "rating_count" in payload:
            updated["rating_count"] = max(0, to_int(payload.get("rating_count"), 0) or 0)

        updated["updated_at"] = now_iso()
        self._set_document(COLLECTIONS["books"], book_id, updated, merge=False)
        return self.get_book(book_id)

    def delete_book(self, book_id: str) -> None:
        existing = self._get_document(COLLECTIONS["books"], book_id)
        if existing is None:
            raise NotFoundError("Book not found")

        for collection in (
            COLLECTIONS["interactions"],
            COLLECTIONS["loans"],
            COLLECTIONS["reservations"],
        ):
            for document in self._list_documents(collection):
                if str(document.get("book_id", "")) == book_id:
                    self._delete_document(collection, str(document["id"]))

        self._delete_document(COLLECTIONS["books"], book_id)

    def _recent_interactions(self) -> list[dict[str, Any]]:
        cutoff = now_utc() - timedelta(days=7)
        interactions = []
        for interaction in self._list_documents(COLLECTIONS["interactions"]):
            created_at = parse_datetime(interaction.get("created_at"), datetime.min.replace(tzinfo=timezone.utc))
            if created_at and created_at >= cutoff:
                interactions.append(interaction)
        return interactions

    def get_trending_books(self) -> list[dict[str, Any]]:
        categories_by_id = self._all_categories_by_id()
        counts: dict[str, int] = {}
        for interaction in self._recent_interactions():
            book_id = non_empty_string(interaction.get("book_id"))
            if book_id is not None:
                counts[book_id] = counts.get(book_id, 0) + 1

        books = {str(book["id"]): book for book in self._list_documents(COLLECTIONS["books"])}
        ranked_ids = sorted(
            counts,
            key=lambda book_id: (-counts[book_id], non_empty_string(books.get(book_id, {}).get("title")) or ""),
        )

        if not ranked_ids:
            fallback = sorted(
                books.values(),
                key=lambda book: (
                    -(to_int(book.get("rating_count"), 0) or 0),
                    -(to_float(book.get("rating"), 0.0) or 0.0),
                    (non_empty_string(book.get("title")) or "").lower(),
                ),
            )
            return [self._book_response(book, categories_by_id) for book in fallback[:10]]

        return [
            self._book_response(books[book_id], categories_by_id)
            for book_id in ranked_ids[:10]
            if book_id in books
        ]

    def get_recommended_books(self, user_id: str) -> list[dict[str, Any]]:
        interactions = [
            interaction
            for interaction in self._list_documents(COLLECTIONS["interactions"])
            if str(interaction.get("user_id", "")) == user_id
        ]
        if not interactions:
            return self.get_trending_books()

        books = {str(book["id"]): book for book in self._list_documents(COLLECTIONS["books"])}
        categories_by_id = self._all_categories_by_id()
        interacted_book_ids = {
            str(interaction["book_id"])
            for interaction in interactions
            if non_empty_string(interaction.get("book_id"))
        }
        preferred_category_ids = {
            non_empty_string(books[book_id].get("category_id"))
            for book_id in interacted_book_ids
            if book_id in books and non_empty_string(books[book_id].get("category_id"))
        }

        if not preferred_category_ids:
            return self.get_trending_books()

        candidates = [
            book
            for book in books.values()
            if non_empty_string(book.get("category_id")) in preferred_category_ids
            and str(book["id"]) not in interacted_book_ids
        ]
        candidates.sort(
            key=lambda book: (
                -(to_int(book.get("rating_count"), 0) or 0),
                -(to_float(book.get("rating"), 0.0) or 0.0),
                (non_empty_string(book.get("title")) or "").lower(),
            )
        )
        return [self._book_response(book, categories_by_id) for book in candidates[:10]]

    def get_user(self, user_id: str) -> dict[str, Any]:
        user = self._get_document(COLLECTIONS["users"], user_id)
        if user is None:
            raise NotFoundError("User not found")
        return self._user_response(user)

    def get_user_by_member(self, member_id: str) -> dict[str, Any]:
        for user in self._list_documents(COLLECTIONS["users"]):
            if str(user.get("member_id", "")) == member_id:
                return self._user_response(user)
        raise NotFoundError("User not found")

    def ensure_user_from_identity(self, identity: dict[str, Any]) -> tuple[dict[str, Any], bool]:
        user_id = non_empty_string(identity.get("sub"))
        if not user_id:
            raise ValidationError("Identity payload is missing subject")

        existing = self._get_document(COLLECTIONS["users"], user_id)
        created = existing is None

        given_name = non_empty_string(identity.get("given_name"))
        family_name = non_empty_string(identity.get("family_name"))
        name = " ".join(part for part in (given_name, family_name) if part)
        if not name:
            name = (
                non_empty_string(identity.get("name"))
                or non_empty_string(identity.get("preferred_username"))
                or non_empty_string(identity.get("username"))
                or non_empty_string(identity.get("email"))
                or user_id
            )

        address = None
        raw_address = identity.get("address")
        if isinstance(raw_address, dict):
            address = non_empty_string(raw_address.get("formatted")) or non_empty_string(
                raw_address.get("street_address")
            )

        timestamp = now_iso()
        user = {
            "id": user_id,
            "member_id": non_empty_string((existing or {}).get("member_id")) or make_member_id(),
            "name": name,
            "email": non_empty_string(identity.get("email")),
            "phone": non_empty_string(identity.get("phone_number")),
            "address": address or non_empty_string((existing or {}).get("address")),
            "profile_image": non_empty_string(identity.get("picture")),
            "joined_date": iso_date_value((existing or {}).get("joined_date"), today_iso()),
            "created_at": iso_datetime_value((existing or {}).get("created_at"), timestamp),
            "updated_at": timestamp,
        }
        self._set_document(COLLECTIONS["users"], user_id, user, merge=False)
        return self._user_response(user), created

    def update_user(self, user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
        existing = self._get_document(COLLECTIONS["users"], user_id)
        if existing is None:
            raise NotFoundError("User not found")

        updated = dict(existing)
        for field in ("name", "email", "phone", "address", "profile_image"):
            if field in payload:
                updated[field] = non_empty_string(payload.get(field))
        updated["updated_at"] = now_iso()
        self._set_document(COLLECTIONS["users"], user_id, updated, merge=False)
        return self._user_response(updated)

    def _sum_unpaid_fines(self, member_id: str) -> float:
        total = 0.0
        for fine in self._list_documents(COLLECTIONS["fines"]):
            if str(fine.get("member_id", "")) != member_id:
                continue
            if (non_empty_string(fine.get("status")) or "unpaid").lower() != "unpaid":
                continue
            total += to_float(fine.get("fine_amount"), 0.0) or 0.0
        return round(total, 2)

    def get_user_stats(self, user_id: str) -> dict[str, Any]:
        self.get_user(user_id)
        self.sync_overdue_loan_fines()

        loans = [
            loan for loan in self._list_documents(COLLECTIONS["loans"])
            if str(loan.get("member_id", "")) == user_id
        ]
        reservations = [
            reservation
            for reservation in self._list_documents(COLLECTIONS["reservations"])
            if str(reservation.get("member_id", "")) == user_id
            and active_reservation_status(non_empty_string(reservation.get("status")))
        ]
        total_borrows = len(loans)
        return {
            "total_borrows": total_borrows,
            "books_read": total_borrows,
            "total_fines": self._sum_unpaid_fines(user_id),
            "active_loans": len(loans),
            "active_reservations": len(reservations),
        }

    def get_settings(self) -> dict[str, Any]:
        return self._settings_response(self._ensure_settings_document())

    def update_settings(self, payload: dict[str, Any]) -> dict[str, Any]:
        existing = self._ensure_settings_document()
        updated = {**existing, **payload, "id": SETTINGS_DOC_ID, "updated_at": now_iso()}
        if "created_at" not in updated:
            updated["created_at"] = now_iso()
        normalized = self._settings_response(updated)
        storage_value = {
            **updated,
            "created_at": normalized["created_at"].isoformat() if normalized["created_at"] else now_iso(),
            "updated_at": normalized["updated_at"].isoformat() if normalized["updated_at"] else now_iso(),
        }
        self._set_document(COLLECTIONS["settings"], SETTINGS_DOC_ID, storage_value, merge=False)
        return self.get_settings()

    def sync_overdue_loan_fines(self) -> None:
        settings = self.get_settings()
        today = today_date()
        daily_fine_rate = max(0.01, float(settings["daily_fine_rate"]))
        max_fine_cap = max(float(settings["max_fine_cap"]), daily_fine_rate)

        for loan in self._list_documents(COLLECTIONS["loans"]):
            due_date = parse_date_value(loan.get("returned_date"))
            member_id = non_empty_string(loan.get("member_id"))
            if due_date is None or member_id is None or due_date >= today:
                continue

            overdue_days = (today - due_date).days
            amount = min(overdue_days * daily_fine_rate, max_fine_cap)
            existing = None
            for fine in self._list_documents(COLLECTIONS["fines"]):
                if str(fine.get("loan_id", "")) == str(loan["id"]):
                    existing = fine
                    break

            timestamp = now_iso()
            fine_id = str(existing["id"]) if existing else make_id("fine_")
            fine = {
                "id": fine_id,
                "member_id": member_id,
                "loan_id": str(loan["id"]),
                "fine_date": today_iso(),
                "fine_amount": round(amount, 2),
                "status": "unpaid",
                "reason": "Overdue return",
                "due_date": due_date.isoformat(),
                "paid_at": existing.get("paid_at") if existing else None,
                "payment_method": existing.get("payment_method") if existing else None,
                "created_at": existing.get("created_at") if existing else timestamp,
                "updated_at": timestamp,
            }
            self._set_document(COLLECTIONS["fines"], fine_id, fine, merge=False)

    def list_loans(self) -> list[dict[str, Any]]:
        return [self._loan_response(loan) for loan in self._list_documents(COLLECTIONS["loans"])]

    def list_active_loans(self, member_id: str | None = None) -> list[dict[str, Any]]:
        loans = self._list_documents(COLLECTIONS["loans"])
        if member_id:
            loans = [loan for loan in loans if str(loan.get("member_id", "")) == member_id]
        return [self._loan_response(loan) for loan in loans]

    def borrow_book(self, book_id: str, member_id: str) -> dict[str, Any]:
        self.sync_overdue_loan_fines()
        user = self._get_document(COLLECTIONS["users"], member_id)
        if user is None:
            raise NotFoundError("Member not found")

        if not non_empty_string(user.get("phone")):
            raise ValidationError("Please update your mobile number before borrowing.")
        if not non_empty_string(user.get("address")):
            raise ValidationError("Please update your address before borrowing.")

        settings = self.get_settings()
        active_loans = [
            loan for loan in self._list_documents(COLLECTIONS["loans"])
            if str(loan.get("member_id", "")) == member_id
        ]
        if len(active_loans) >= int(settings["max_books_per_user"]):
            raise ValidationError(
                "Borrowing limit reached. "
                f"Maximum books per user is {settings['max_books_per_user']}."
            )

        if bool(settings["block_on_unpaid_fines"]):
            total_fines = self._sum_unpaid_fines(member_id)
            if total_fines >= float(settings["fine_threshold"]):
                raise ValidationError(
                    "Borrowing blocked due to unpaid fines above threshold. "
                    f"Current fines: {total_fines:.2f}, "
                    f"threshold: {float(settings['fine_threshold']):.2f}."
                )

        for loan in active_loans:
            if str(loan.get("book_id", "")) == book_id:
                raise ConflictError(
                    "You already borrowed this book. Return it before borrowing again."
                )

        book = self._get_document(COLLECTIONS["books"], book_id)
        if book is None:
            raise NotFoundError("Book not found")

        copies_available = max(0, to_int(book.get("copies_available"), to_int(book.get("copies_owned"), 0) or 0) or 0)
        if copies_available <= 0:
            raise ValidationError("No copies available")

        loan_id = make_id("loan_")
        loan_period = int(settings["loan_period_days"])
        loan_data = {
            "id": loan_id,
            "book_id": book_id,
            "member_id": member_id,
            "loan_date": today_iso(),
            "returned_date": (today_date() + timedelta(days=loan_period)).isoformat(),
            "created_at": now_iso(),
            "updated_at": now_iso(),
        }
        self._set_document(COLLECTIONS["loans"], loan_id, loan_data, merge=False)

        updated_book = {
            **book,
            "copies_available": copies_available - 1,
            "updated_at": now_iso(),
        }
        self._set_document(COLLECTIONS["books"], book_id, updated_book, merge=False)

        interaction_id = make_id("interaction_")
        self._set_document(
            COLLECTIONS["interactions"],
            interaction_id,
            {
                "id": interaction_id,
                "user_id": member_id,
                "book_id": book_id,
                "interaction_type": "checkout",
                "created_at": now_iso(),
            },
            merge=False,
        )

        return self._loan_response(loan_data)

    def return_book(self, loan_id: str) -> dict[str, Any]:
        loan = self._get_document(COLLECTIONS["loans"], loan_id)
        if loan is None:
            raise NotFoundError("Loan not found")

        book_id = str(loan.get("book_id", ""))
        book = self._get_document(COLLECTIONS["books"], book_id)
        if book is not None:
            copies_available = max(
                0,
                to_int(book.get("copies_available"), to_int(book.get("copies_owned"), 0) or 0)
                or 0,
            )
            updated_book = {
                **book,
                "copies_available": copies_available + 1,
                "updated_at": now_iso(),
            }
            self._set_document(COLLECTIONS["books"], book_id, updated_book, merge=False)

        self._delete_document(COLLECTIONS["loans"], loan_id)
        return {"message": "Book returned successfully"}

    def renew_loan(self, loan_id: str) -> dict[str, Any]:
        loan = self._get_document(COLLECTIONS["loans"], loan_id)
        if loan is None:
            raise NotFoundError("Loan not found")

        settings = self.get_settings()
        base_date = parse_date_value(loan.get("returned_date"), today_date()) or today_date()
        if base_date < today_date():
            base_date = today_date()

        updated = {
            **loan,
            "returned_date": (base_date + timedelta(days=int(settings["loan_period_days"]))).isoformat(),
            "updated_at": now_iso(),
        }
        self._set_document(COLLECTIONS["loans"], loan_id, updated, merge=False)
        return self._loan_response(updated)

    def list_reservations(self) -> list[dict[str, Any]]:
        reservations = self._list_documents(COLLECTIONS["reservations"])
        return [self._reservation_response(reservation) for reservation in reservations]

    def get_reservation(self, reservation_id: str) -> dict[str, Any]:
        reservation = self._get_document(COLLECTIONS["reservations"], reservation_id)
        if reservation is None:
            raise NotFoundError("Reservation not found")
        return self._reservation_response(reservation)

    def get_reservations_for_member(self, member_id: str) -> list[dict[str, Any]]:
        reservations = [
            reservation
            for reservation in self._list_documents(COLLECTIONS["reservations"])
            if str(reservation.get("member_id", "")) == member_id
        ]
        return [self._reservation_response(reservation) for reservation in reservations]

    def create_reservation(self, payload: dict[str, Any]) -> dict[str, Any]:
        book_id = non_empty_string(payload.get("book_id"))
        member_id = non_empty_string(payload.get("member_id"))
        if not book_id or not member_id:
            raise ValidationError("book_id and member_id are required")

        if self._get_document(COLLECTIONS["books"], book_id) is None:
            raise NotFoundError("Book not found")

        for loan in self._list_documents(COLLECTIONS["loans"]):
            if str(loan.get("book_id", "")) == book_id and str(loan.get("member_id", "")) == member_id:
                raise ConflictError(
                    "You already borrowed this book. Return it before reserving."
                )

        for reservation in self._list_documents(COLLECTIONS["reservations"]):
            if (
                str(reservation.get("book_id", "")) == book_id
                and str(reservation.get("member_id", "")) == member_id
                and active_reservation_status(non_empty_string(reservation.get("status")))
            ):
                raise ConflictError("You already reserved this book.")

        reservation_id = make_id("reservation_")
        reservation = {
            "id": reservation_id,
            "book_id": book_id,
            "member_id": member_id,
            "reservation_date": iso_date_value(payload.get("reservation_date"), today_iso()),
            "status": non_empty_string(payload.get("status")) or "Pending",
            "created_at": now_iso(),
            "updated_at": now_iso(),
        }
        self._set_document(COLLECTIONS["reservations"], reservation_id, reservation)
        return self._reservation_response(reservation)

    def cancel_reservation(self, reservation_id: str) -> dict[str, Any]:
        reservation = self._get_document(COLLECTIONS["reservations"], reservation_id)
        if reservation is None:
            raise NotFoundError("Reservation not found")
        updated = {
            **reservation,
            "status": "Cancelled",
            "updated_at": now_iso(),
        }
        self._set_document(COLLECTIONS["reservations"], reservation_id, updated, merge=False)
        return self._reservation_response(updated)

    def list_favorites(self, member_id: str) -> list[dict[str, Any]]:
        book_ids = self.get_favorite_ids(member_id)["book_ids"]
        categories_by_id = self._all_categories_by_id()
        books = {str(book["id"]): book for book in self._list_documents(COLLECTIONS["books"])}
        return [
            self._book_response(books[book_id], categories_by_id)
            for book_id in book_ids
            if book_id in books
        ]

    def get_favorite_ids(self, member_id: str) -> dict[str, Any]:
        interactions = [
            interaction
            for interaction in self._list_documents(COLLECTIONS["interactions"])
            if str(interaction.get("user_id", "")) == member_id
            and (non_empty_string(interaction.get("interaction_type")) or "") == "like"
        ]
        return {
            "book_ids": [str(interaction["book_id"]) for interaction in interactions if interaction.get("book_id")]
        }

    def add_favorite(self, member_id: str, book_id: str) -> dict[str, Any]:
        if self._get_document(COLLECTIONS["books"], book_id) is None:
            raise NotFoundError("Book not found")

        for interaction in self._list_documents(COLLECTIONS["interactions"]):
            if (
                str(interaction.get("user_id", "")) == member_id
                and str(interaction.get("book_id", "")) == book_id
                and (non_empty_string(interaction.get("interaction_type")) or "") == "like"
            ):
                return {"message": "Book already in favorites", "is_favorite": True}

        interaction_id = make_id("interaction_")
        self._set_document(
            COLLECTIONS["interactions"],
            interaction_id,
            {
                "id": interaction_id,
                "user_id": member_id,
                "book_id": book_id,
                "interaction_type": "like",
                "created_at": now_iso(),
            },
            merge=False,
        )
        return {"message": "Book added to favorites", "is_favorite": True}

    def remove_favorite(self, member_id: str, book_id: str) -> dict[str, Any]:
        for interaction in self._list_documents(COLLECTIONS["interactions"]):
            if (
                str(interaction.get("user_id", "")) == member_id
                and str(interaction.get("book_id", "")) == book_id
                and (non_empty_string(interaction.get("interaction_type")) or "") == "like"
            ):
                self._delete_document(COLLECTIONS["interactions"], str(interaction["id"]))
                return {"message": "Book removed from favorites", "is_favorite": False}
        return {"message": "Book not in favorites", "is_favorite": False}

    def check_favorite(self, member_id: str, book_id: str) -> dict[str, Any]:
        for interaction in self._list_documents(COLLECTIONS["interactions"]):
            if (
                str(interaction.get("user_id", "")) == member_id
                and str(interaction.get("book_id", "")) == book_id
                and (non_empty_string(interaction.get("interaction_type")) or "") == "like"
            ):
                return {"is_favorite": True}
        return {"is_favorite": False}


class FirestoreLibraryStore(BaseLibraryStore):
    def __init__(self):
        self._db = get_firestore_client()

    def _list_documents(self, collection: str) -> list[dict[str, Any]]:
        return [
            {"id": document.id, **(document.to_dict() or {})}
            for document in self._db.collection(collection).stream()
        ]

    def _get_document(self, collection: str, doc_id: str) -> dict[str, Any] | None:
        snapshot = self._db.collection(collection).document(doc_id).get()
        if not snapshot.exists:
            return None
        return {"id": snapshot.id, **(snapshot.to_dict() or {})}

    def _set_document(
        self, collection: str, doc_id: str, data: dict[str, Any], merge: bool = False
    ) -> None:
        self._db.collection(collection).document(doc_id).set(
            {"id": doc_id, **data},
            merge=merge,
        )

    def _delete_document(self, collection: str, doc_id: str) -> None:
        self._db.collection(collection).document(doc_id).delete()

    def project_id(self) -> str:
        return resolve_firebase_config()["project_id"]


class InMemoryLibraryStore(BaseLibraryStore):
    def __init__(self):
        self._collections: dict[str, dict[str, dict[str, Any]]] = {
            collection_name: {}
            for collection_name in COLLECTIONS.values()
        }
        self._project = "test-project"

    def _list_documents(self, collection: str) -> list[dict[str, Any]]:
        return deepcopy(list(self._collections[collection].values()))

    def _get_document(self, collection: str, doc_id: str) -> dict[str, Any] | None:
        value = self._collections[collection].get(doc_id)
        return deepcopy(value) if value is not None else None

    def _set_document(
        self, collection: str, doc_id: str, data: dict[str, Any], merge: bool = False
    ) -> None:
        if merge and doc_id in self._collections[collection]:
            stored = deepcopy(self._collections[collection][doc_id])
            stored.update(deepcopy(data))
            stored["id"] = doc_id
            self._collections[collection][doc_id] = stored
            return

        self._collections[collection][doc_id] = {"id": doc_id, **deepcopy(data)}

    def _delete_document(self, collection: str, doc_id: str) -> None:
        self._collections[collection].pop(doc_id, None)

    def project_id(self) -> str:
        return self._project


LibraryStore = BaseLibraryStore
