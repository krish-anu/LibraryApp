from datetime import datetime
from datetime import date

from sqlalchemy import Date, DateTime, LargeBinary, TEXT, VARCHAR
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True)
    member_id: Mapped[str | None] = mapped_column(TEXT)
    name: Mapped[str | None] = mapped_column(VARCHAR(100))
    email: Mapped[str | None] = mapped_column(VARCHAR(100))
    password: Mapped[bytes | None] = mapped_column(LargeBinary)
    phone: Mapped[str | None] = mapped_column(VARCHAR(20), nullable=True)
    address: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    profile_image: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    profile_image_blob: Mapped[bytes | None] = mapped_column(
        LargeBinary,
        nullable=True,
    )
    profile_image_mime_type: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    joined_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )
