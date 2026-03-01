from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, INTEGER, NUMERIC, TEXT

from .base import Base


class Settings(Base):
    __tablename__ = "settings"

    id = Column(TEXT, primary_key=True)
    loan_period_days = Column(INTEGER, nullable=False, default=14)
    max_books_per_user = Column(INTEGER, nullable=False, default=5)
    grace_period_days = Column(INTEGER, nullable=False, default=2)
    daily_fine_rate = Column(NUMERIC(10, 2), nullable=False, default=0.50)
    max_fine_cap = Column(NUMERIC(10, 2), nullable=False, default=25.00)
    block_on_unpaid_fines = Column(Boolean, nullable=False, default=True)
    fine_threshold = Column(NUMERIC(10, 2), nullable=False, default=10.00)
    send_notifications = Column(Boolean, nullable=False, default=True)
    notification_days_before_due = Column(INTEGER, nullable=False, default=3)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
