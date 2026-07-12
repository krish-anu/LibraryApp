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
    yield
