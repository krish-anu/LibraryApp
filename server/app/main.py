from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from .database import engine
from .models.base import Base

# Import models package to ensure all model modules are loaded and registered with SQLAlchemy
from . import models  # noqa: F401
from .routers import (
    books,
    loans,
    general,
    category,
    favorites,
    users,
    reservations,
    auth,
    settings,
)


def _ensure_users_columns() -> None:
    with engine.connect() as conn:
        conn.exec_driver_sql(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20)"
        )
        conn.exec_driver_sql("ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT")
        conn.exec_driver_sql(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image TEXT"
        )
        conn.exec_driver_sql(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS joined_date DATE"
        )
        conn.exec_driver_sql(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP"
        )
        conn.exec_driver_sql(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP"
        )
        conn.exec_driver_sql(
            "UPDATE users SET created_at = NOW() WHERE created_at IS NULL"
        )
        conn.exec_driver_sql(
            "UPDATE users SET updated_at = NOW() WHERE updated_at IS NULL"
        )
        conn.exec_driver_sql(
            "ALTER TABLE users ALTER COLUMN created_at SET DEFAULT NOW()"
        )
        conn.exec_driver_sql(
            "ALTER TABLE users ALTER COLUMN updated_at SET DEFAULT NOW()"
        )
        conn.commit()


def _ensure_settings_row() -> None:
    with engine.connect() as conn:
        conn.exec_driver_sql(
            """
            INSERT INTO settings (
                id,
                loan_period_days,
                max_books_per_user,
                grace_period_days,
                daily_fine_rate,
                max_fine_cap,
                block_on_unpaid_fines,
                fine_threshold,
                send_notifications,
                notification_days_before_due,
                created_at,
                updated_at
            )
            SELECT
                '00000000-0000-0000-0000-000000000001',
                14,
                5,
                2,
                0.50,
                25.00,
                true,
                10.00,
                true,
                3,
                NOW(),
                NOW()
            WHERE NOT EXISTS (SELECT 1 FROM settings)
            """
        )
        conn.commit()


def _ensure_fine_columns() -> None:
    with engine.connect() as conn:
        conn.exec_driver_sql(
            "ALTER TABLE fines ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'unpaid'"
        )
        conn.exec_driver_sql("ALTER TABLE fines ADD COLUMN IF NOT EXISTS reason TEXT")
        conn.exec_driver_sql("ALTER TABLE fines ADD COLUMN IF NOT EXISTS due_date DATE")
        conn.exec_driver_sql(
            "ALTER TABLE fines ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP"
        )
        conn.exec_driver_sql(
            "ALTER TABLE fines ADD COLUMN IF NOT EXISTS payment_method TEXT"
        )
        conn.exec_driver_sql(
            "ALTER TABLE fines ADD COLUMN IF NOT EXISTS created_at TIMESTAMP"
        )
        conn.exec_driver_sql(
            "ALTER TABLE fines ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP"
        )
        conn.exec_driver_sql(
            "UPDATE fines SET status = 'unpaid' WHERE status IS NULL OR TRIM(status) = ''"
        )
        conn.exec_driver_sql(
            """
            CREATE TABLE IF NOT EXISTS fine_payments (
                id TEXT PRIMARY KEY,
                member_id TEXT REFERENCES users(id),
                payment_date DATE,
                payment_amount NUMERIC
            )
            """
        )
        conn.exec_driver_sql(
            "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS fine_id TEXT REFERENCES fines(id) ON DELETE CASCADE"
        )
        conn.exec_driver_sql(
            "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'physical'"
        )
        conn.exec_driver_sql(
            "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS handled_by TEXT"
        )
        conn.exec_driver_sql(
            "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS notes TEXT"
        )
        conn.exec_driver_sql(
            "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS created_at TIMESTAMP"
        )
        conn.exec_driver_sql(
            "UPDATE fine_payments SET payment_method = 'physical' WHERE payment_method IS NULL OR TRIM(payment_method) = ''"
        )
        conn.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    _ensure_users_columns()
    _ensure_settings_row()
    _ensure_fine_columns()
    yield


app = FastAPI(title="Library App API", lifespan=lifespan)

# Serve client assets (book covers etc.) at /assets
project_root = Path(__file__).resolve().parents[1].parent
client_assets = project_root / "client" / "assets"
if client_assets.exists():
    app.mount("/assets", StaticFiles(directory=str(client_assets)), name="assets")

app.include_router(general.router)
app.include_router(auth.router)
app.include_router(books.router)
app.include_router(loans.router)
app.include_router(category.router)
app.include_router(favorites.router)
app.include_router(users.router)
app.include_router(reservations.router)
app.include_router(settings.router)
