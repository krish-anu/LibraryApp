from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, Integer, String, TEXT
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


# models/interactions.py
class Interaction(Base):
    __tablename__ = "interactions"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("users.id"))
    book_id: Mapped[str | None] = mapped_column(TEXT, ForeignKey("books.id"))
    interaction_type: Mapped[str | None] = mapped_column(String)
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
