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
            text(
                "ALTER TABLE loans ADD COLUMN IF NOT EXISTS "
                "renewal_count INTEGER NOT NULL DEFAULT 0"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE settings ADD COLUMN IF NOT EXISTS "
                "max_renewals INTEGER NOT NULL DEFAULT 1"
            )
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
        conn.execute(
            text(
                "UPDATE reservations SET status = 'pending' "
                "WHERE status IS NULL OR TRIM(status) = ''"
            )
        )
        conn.execute(
            text("ALTER TABLE reservations ADD COLUMN IF NOT EXISTS queued_at TIMESTAMPTZ")
        )
        # PostgreSQL enforces the invariants that application-level checks alone
        # cannot protect under concurrent requests. NOT VALID preserves startup
        # for legacy rows while still enforcing each constraint for new writes.
        for constraint_sql in (
            "ALTER TABLE books ADD CONSTRAINT ck_books_copies_nonnegative "
            "CHECK (copies_owned IS NULL OR copies_owned >= 0) NOT VALID",
            "ALTER TABLE loans ADD CONSTRAINT ck_loans_status "
            "CHECK (status IS NULL OR lower(status) IN ('active', 'returned')) NOT VALID",
            "ALTER TABLE loans ADD CONSTRAINT ck_loans_renewal_count "
            "CHECK (renewal_count >= 0) NOT VALID",
            "ALTER TABLE reservations ADD CONSTRAINT ck_reservations_status "
            "CHECK (status IS NULL OR lower(status) IN "
            "('pending', 'ready', 'cancelled', 'canceled', 'expired', 'completed', 'fulfilled')) NOT VALID",
            "ALTER TABLE fines ADD CONSTRAINT ck_fines_amount_nonnegative "
            "CHECK (fine_amount IS NULL OR fine_amount >= 0) NOT VALID",
            "ALTER TABLE fines ADD CONSTRAINT ck_fines_status "
            "CHECK (status IS NULL OR lower(status) IN ('unpaid', 'paid', 'waived')) NOT VALID",
            "ALTER TABLE fine_payments ADD CONSTRAINT ck_fine_payments_amount_positive "
            "CHECK (payment_amount IS NULL OR payment_amount > 0) NOT VALID",
        ):
            constraint_name = constraint_sql.split(" ADD CONSTRAINT ", 1)[1].split()[0]
            conn.execute(
                text(
                    "DO $$ BEGIN "
                    "IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = "
                    f"'{constraint_name}') THEN {constraint_sql}; END IF; END $$;"
                )
            )
        conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS uq_loans_active_member_book "
                "ON loans (member_id, book_id) "
                "WHERE lower(coalesce(status, 'active')) = 'active'"
            )
        )
        conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS uq_reservations_active_member_book "
                "ON reservations (member_id, book_id) "
                "WHERE status IS NULL OR lower(status) IN ('pending', 'ready')"
            )
        )
        conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_reservations_queue_order "
                "ON reservations (book_id, queued_at NULLS FIRST, "
                "reservation_date NULLS FIRST, id) "
                "WHERE status IS NULL OR lower(status) IN ('pending', 'ready')"
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
