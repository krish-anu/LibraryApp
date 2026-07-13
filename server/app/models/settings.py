from datetime import datetime

from sqlalchemy import Boolean, DateTime, INTEGER, NUMERIC, TEXT
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class Settings(Base):
    __tablename__ = "settings"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    loan_period_days: Mapped[int] = mapped_column(INTEGER, nullable=False, default=14)
    max_books_per_user: Mapped[int] = mapped_column(INTEGER, nullable=False, default=5)
    grace_period_days: Mapped[int] = mapped_column(INTEGER, nullable=False, default=2)
    daily_fine_rate: Mapped[float] = mapped_column(
        NUMERIC(10, 2), nullable=False, default=0.50
    )
    max_fine_cap: Mapped[float] = mapped_column(
        NUMERIC(10, 2), nullable=False, default=25.00
    )
    block_on_unpaid_fines: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    fine_threshold: Mapped[float] = mapped_column(
        NUMERIC(10, 2), nullable=False, default=10.00
    )
    send_notifications: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    notification_days_before_due: Mapped[int] = mapped_column(
        INTEGER, nullable=False, default=3
    )
    sheet_sync_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sheet_sync_interval_days: Mapped[int] = mapped_column(INTEGER, nullable=False, default=30)
    sheet_spreadsheet_id: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    sheet_books_tab: Mapped[str | None] = mapped_column(TEXT, nullable=True, default="Books")
    sheet_blogs_tab: Mapped[str | None] = mapped_column(TEXT, nullable=True, default="Blogs")
    sheet_videos_tab: Mapped[str | None] = mapped_column(TEXT, nullable=True, default="Videos")
    sheet_last_sync_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    sheet_last_sync_status: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    sheet_last_sync_message: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
