from __future__ import annotations

import csv
import io
import os
from dataclasses import dataclass
from datetime import datetime
from urllib.parse import quote, unquote, urlparse

import httpx
from sqlalchemy.orm import Session

from app.models.author import Author
from app.models.book import Book
from app.models.category import Category
from app.models.content import BlogPost, VideoPost
from app.models.settings import Settings


SPREADSHEET_ID_ENV_NAMES = (
    "GOOGLE_SHEET_SPREADSHEET_ID",
    "GOOGLE_SHEET_ID",
    "SHEET_SPREADSHEET_ID",
)
SHEET_TAB_ENV_NAMES = {
    "books": "GOOGLE_SHEET_BOOKS_TAB",
    "blogs": "GOOGLE_SHEET_BLOGS_TAB",
    "videos": "GOOGLE_SHEET_VIDEOS_TAB",
}
DEFAULT_SHEET_TABS = {
    "books": "Books",
    "blogs": "Blogs",
    "videos": "Videos",
}


@dataclass
class SheetSyncResult:
    books_created: int = 0
    books_updated: int = 0
    blogs_created: int = 0
    blogs_updated: int = 0
    videos_created: int = 0
    videos_updated: int = 0

    @property
    def total(self) -> int:
        return (
            self.books_created
            + self.books_updated
            + self.blogs_created
            + self.blogs_updated
            + self.videos_created
            + self.videos_updated
        )

    def as_dict(self) -> dict[str, int]:
        return {
            "books_created": self.books_created,
            "books_updated": self.books_updated,
            "blogs_created": self.blogs_created,
            "blogs_updated": self.blogs_updated,
            "videos_created": self.videos_created,
            "videos_updated": self.videos_updated,
            "total": self.total,
        }


def _clean(value: object) -> str:
    return str(value or "").strip()


def normalize_spreadsheet_id(value: object) -> str:
    cleaned = _clean(value)
    if not cleaned:
        return ""

    parsed = urlparse(cleaned)
    if parsed.netloc and "docs.google.com" in parsed.netloc:
        parts = [unquote(part) for part in parsed.path.split("/") if part]
        try:
            spreadsheets_index = parts.index("spreadsheets")
            if parts[spreadsheets_index + 1] == "d":
                return parts[spreadsheets_index + 2].strip()
        except (ValueError, IndexError):
            return cleaned

    return cleaned


def env_spreadsheet_id() -> str:
    for env_name in SPREADSHEET_ID_ENV_NAMES:
        spreadsheet_id = normalize_spreadsheet_id(os.getenv(env_name))
        if spreadsheet_id:
            return spreadsheet_id
    return ""


def env_sheet_tab(content_type: str) -> str:
    return _clean(os.getenv(SHEET_TAB_ENV_NAMES[content_type])) or DEFAULT_SHEET_TABS[
        content_type
    ]


def _bool(value: object, default: bool = False) -> bool:
    cleaned = _clean(value).lower()
    if cleaned in {"true", "1", "yes", "y", "published"}:
        return True
    if cleaned in {"false", "0", "no", "n", "draft", "unpublished"}:
        return False
    return default


def _int(value: object, default: int = 0) -> int:
    try:
        return int(float(_clean(value)))
    except (TypeError, ValueError):
        return default


def _date(value: object) -> datetime:
    cleaned = _clean(value)
    if not cleaned:
        return datetime.utcnow()
    try:
        return datetime.fromisoformat(cleaned.replace("Z", "+00:00")).replace(tzinfo=None)
    except ValueError:
        return datetime.utcnow()


def _publication_year(value: object) -> int:
    cleaned = _clean(value)
    if len(cleaned) >= 4 and cleaned[:4].isdigit():
        return int(cleaned[:4])
    return _int(cleaned, 0)


def _sheet_csv_url(spreadsheet_id: str, tab_name: str) -> str:
    return (
        "https://docs.google.com/spreadsheets/d/"
        f"{quote(spreadsheet_id, safe='')}/gviz/tq?"
        f"tqx=out:csv&sheet={quote(tab_name, safe='')}"
    )


def _fetch_rows(spreadsheet_id: str, tab_name: str) -> list[dict[str, str]]:
    if not spreadsheet_id or not tab_name:
        return []

    response = httpx.get(_sheet_csv_url(spreadsheet_id, tab_name), timeout=30)
    response.raise_for_status()
    reader = csv.DictReader(io.StringIO(response.text))
    rows = []
    for row in reader:
        normalized = {str(key or "").strip(): _clean(value) for key, value in row.items()}
        if normalized.get("id"):
            rows.append(normalized)
    return rows


def _get_or_create_category(db: Session, name: str) -> Category:
    cleaned = name or "Uncategorized"
    category = db.query(Category).filter(Category.name == cleaned).first()
    if category:
        return category
    category = Category(id=f"cat_{cleaned.lower().replace(' ', '_')}", name=cleaned)
    db.add(category)
    db.flush()
    return category


def _get_or_create_author(db: Session, name: str) -> Author:
    cleaned = name or "Unknown Author"
    existing = db.query(Author).all()
    for author in existing:
        full_name = f"{author.first_name or ''} {author.last_name or ''}".strip()
        if full_name.lower() == cleaned.lower():
            return author

    parts = cleaned.split()
    first_name = " ".join(parts[:-1]) if len(parts) > 1 else cleaned
    last_name = parts[-1] if len(parts) > 1 else ""
    author = Author(
        id=f"author_{abs(hash(cleaned))}",
        first_name=first_name,
        last_name=last_name,
    )
    db.add(author)
    db.flush()
    return author


def _sync_books(db: Session, rows: list[dict[str, str]], result: SheetSyncResult) -> None:
    for row in rows:
        book = db.query(Book).filter(Book.id == row["id"]).first()
        if book:
            result.books_updated += 1
        else:
            book = Book(id=row["id"])
            db.add(book)
            result.books_created += 1

        category = _get_or_create_category(db, row.get("category") or "Uncategorized")
        author = _get_or_create_author(db, row.get("author") or "Unknown Author")
        book.title = row.get("title") or book.title
        book.subtitle = row.get("subtitle") or None
        book.description = row.get("description") or ""
        book.author_id = author.id
        book.category_id = category.id
        book.publisher = row.get("publisher") or None
        book.isbn_10 = row.get("isbn_10") or None
        book.isbn_13 = row.get("isbn_13") or None
        book.publication_year = _publication_year(row.get("published_date"))
        book.published_date = row.get("published_date") or None
        book.copies_owned = max(1, _int(row.get("copies_owned"), 1))
        book.image = row.get("cover_image_url") or row.get("image") or book.image
        book.language = row.get("language") or "English"
        book.pages = _int(row.get("page_count"), 200)
        book.rating = book.rating or 0
        book.rating_count = book.rating_count or 0
        book.tags = row.get("tags") or None
        book.edition = row.get("edition") or None
        book.book_url = row.get("book_url") or None
        book.featured = row.get("featured") or None
        book.sort_order = _int(row.get("sort_order"), 0)
        book.sheet_created_at = row.get("created_at") or None


def _sync_blogs(db: Session, rows: list[dict[str, str]], result: SheetSyncResult) -> None:
    for row in rows:
        blog = db.query(BlogPost).filter(BlogPost.id == row["id"]).first()
        if blog:
            result.blogs_updated += 1
        else:
            blog = BlogPost(id=row["id"])
            db.add(blog)
            result.blogs_created += 1

        blog.title = row.get("title") or blog.title
        blog.excerpt = row.get("description") or row.get("excerpt") or ""
        blog.content = row.get("description") or row.get("content") or ""
        blog.url = row.get("url") or None
        blog.cover_image = row.get("thumbnail_url") or row.get("cover_image") or None
        blog.author = row.get("author") or "Library Team"
        blog.source = row.get("source") or None
        blog.category = row.get("category") or "Library"
        blog.tags = row.get("tags") or None
        blog.language = row.get("language") or None
        blog.featured = _bool(row.get("featured"))
        blog.status = row.get("status") or ("published" if blog.published else "draft")
        blog.published = _bool(row.get("status"), True)
        blog.published_at = _date(row.get("published_date"))
        blog.sort_order = _int(row.get("sort_order"), 0)
        blog.read_minutes = max(1, _int(row.get("read_minutes"), 3))


def _sync_videos(db: Session, rows: list[dict[str, str]], result: SheetSyncResult) -> None:
    for row in rows:
        video = db.query(VideoPost).filter(VideoPost.id == row["id"]).first()
        if video:
            result.videos_updated += 1
        else:
            video = VideoPost(id=row["id"])
            db.add(video)
            result.videos_created += 1

        video.youtube_video_id = row.get("youtube_video_id") or video.youtube_video_id
        video.title = row.get("title") or video.title
        video.description = row.get("description") or ""
        video.youtube_url = row.get("youtube_url") or None
        video.thumbnail_url = row.get("thumbnail_url") or None
        video.speaker = row.get("channel_name") or row.get("speaker") or "Library Team"
        video.channel_name = row.get("channel_name") or None
        video.category = row.get("category") or "Learning"
        video.tags = row.get("tags") or None
        video.duration = row.get("duration") or ""
        video.language = row.get("language") or None
        video.featured = _bool(row.get("featured"))
        video.status = row.get("status") or ("published" if video.published else "draft")
        video.published = _bool(row.get("status"), True)
        video.published_at = _date(row.get("published_date"))
        video.sort_order = _int(row.get("sort_order"), 0)


def run_sheet_sync(db: Session, settings: Settings) -> SheetSyncResult:
    spreadsheet_id = env_spreadsheet_id()
    if not spreadsheet_id:
        raise ValueError(
            "Google Spreadsheet ID is required in server env "
            f"({SPREADSHEET_ID_ENV_NAMES[0]})"
        )

    result = SheetSyncResult()
    books_rows = _fetch_rows(spreadsheet_id, env_sheet_tab("books"))
    blogs_rows = _fetch_rows(spreadsheet_id, env_sheet_tab("blogs"))
    videos_rows = _fetch_rows(spreadsheet_id, env_sheet_tab("videos"))

    _sync_books(db, books_rows, result)
    _sync_blogs(db, blogs_rows, result)
    _sync_videos(db, videos_rows, result)

    settings.sheet_last_sync_at = datetime.utcnow()
    settings.sheet_last_sync_status = "success"
    settings.sheet_last_sync_message = f"Synced {result.total} rows"
    db.commit()
    return result
