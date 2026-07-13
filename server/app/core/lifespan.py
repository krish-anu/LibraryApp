from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import text

from app.db import engine
from app.models.base import Base
from app import models  # noqa: F401


def _ensure_schema_columns() -> None:
    if engine.dialect.name != "postgresql":
        return

    with engine.begin() as conn:
        conn.execute(
            text("ALTER TABLE loans ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active'")
        )
        conn.execute(
            text("ALTER TABLE loans ADD COLUMN IF NOT EXISTS returned_at DATE")
        )
        conn.execute(
            text("ALTER TABLE loans ADD COLUMN IF NOT EXISTS returned_by TEXT")
        )
        conn.execute(
            text("ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_blob BYTEA")
        )
        conn.execute(
            text(
                "ALTER TABLE users "
                "ADD COLUMN IF NOT EXISTS profile_image_mime_type TEXT"
            )
        )
        conn.execute(
            text("ALTER TABLE books ADD COLUMN IF NOT EXISTS image_blob BYTEA")
        )
        conn.execute(
            text("ALTER TABLE books ADD COLUMN IF NOT EXISTS image_mime_type TEXT")
        )
        for column in (
            "subtitle TEXT",
            "publisher TEXT",
            "isbn_10 TEXT",
            "isbn_13 TEXT",
            "tags TEXT",
            "published_date TEXT",
            "edition TEXT",
            "book_url TEXT",
            "featured TEXT",
            "sort_order NUMERIC",
            "sheet_created_at TEXT",
        ):
            conn.execute(text(f"ALTER TABLE books ADD COLUMN IF NOT EXISTS {column}"))
        for column in (
            "sheet_sync_enabled BOOLEAN NOT NULL DEFAULT FALSE",
            "sheet_sync_interval_days INTEGER NOT NULL DEFAULT 30",
            "sheet_spreadsheet_id TEXT",
            "sheet_books_tab TEXT DEFAULT 'Books'",
            "sheet_blogs_tab TEXT DEFAULT 'Blogs'",
            "sheet_videos_tab TEXT DEFAULT 'Videos'",
            "sheet_last_sync_at TIMESTAMP",
            "sheet_last_sync_status TEXT",
            "sheet_last_sync_message TEXT",
        ):
            conn.execute(text(f"ALTER TABLE settings ADD COLUMN IF NOT EXISTS {column}"))
        for column in (
            "url TEXT",
            "source TEXT",
            "tags TEXT",
            "language TEXT",
            "featured BOOLEAN NOT NULL DEFAULT FALSE",
            "status TEXT",
            "sort_order INTEGER",
        ):
            conn.execute(text(f"ALTER TABLE blog_posts ADD COLUMN IF NOT EXISTS {column}"))
        for column in (
            "youtube_url TEXT",
            "channel_name TEXT",
            "tags TEXT",
            "language TEXT",
            "featured BOOLEAN NOT NULL DEFAULT FALSE",
            "status TEXT",
            "sort_order INTEGER",
        ):
            conn.execute(text(f"ALTER TABLE video_posts ADD COLUMN IF NOT EXISTS {column}"))
        conn.execute(
            text(
                "UPDATE loans SET status = 'active' "
                "WHERE status IS NULL OR TRIM(status) = ''"
            )
        )


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    _ensure_schema_columns()
    from app.services.sheet_sync.scheduler import sheet_sync_scheduler

    await sheet_sync_scheduler.start()
    try:
        yield
    finally:
        await sheet_sync_scheduler.stop()
