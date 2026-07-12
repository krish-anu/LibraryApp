from __future__ import annotations

from datetime import datetime
from uuid import uuid4

from sqlalchemy import Boolean, DateTime, Integer, TEXT
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class BlogPost(Base):
    __tablename__ = "blog_posts"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid4()))
    title: Mapped[str] = mapped_column(TEXT, nullable=False)
    excerpt: Mapped[str] = mapped_column(TEXT, nullable=False, default="")
    content: Mapped[str] = mapped_column(TEXT, nullable=False, default="")
    author: Mapped[str] = mapped_column(TEXT, nullable=False, default="Library Team")
    category: Mapped[str] = mapped_column(TEXT, nullable=False, default="Library")
    cover_image: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    read_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=3)
    published: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    published_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, default=datetime.utcnow, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )


class VideoPost(Base):
    __tablename__ = "video_posts"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid4()))
    title: Mapped[str] = mapped_column(TEXT, nullable=False)
    description: Mapped[str] = mapped_column(TEXT, nullable=False, default="")
    youtube_video_id: Mapped[str] = mapped_column(TEXT, nullable=False)
    speaker: Mapped[str] = mapped_column(TEXT, nullable=False, default="Library Team")
    category: Mapped[str] = mapped_column(TEXT, nullable=False, default="Learning")
    duration: Mapped[str] = mapped_column(TEXT, nullable=False, default="")
    thumbnail_url: Mapped[str | None] = mapped_column(TEXT, nullable=True)
    published: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    published_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, default=datetime.utcnow, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )
