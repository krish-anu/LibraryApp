from .base import Base
from sqlalchemy import Column, Integer, ForeignKey, String, DateTime, TEXT
from datetime import datetime, timezone


# models/interactions.py
class Interaction(Base):
    __tablename__ = "interactions"
    id = Column(Integer, primary_key=True)
    user_id = Column(TEXT, ForeignKey("users.id"))
    book_id = Column(TEXT, ForeignKey("books.id"))
    interaction_type = Column(String)  # 'view', 'checkout', 'like'
    created_at = Column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
