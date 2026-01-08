from .base import Base
from sqlalchemy import Column,Integer,ForeignKey,String,DateTime
from datetime import datetime,timezone

# models/interactions.py
class Interaction(Base):
    __tablename__ = "interactions"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    book_id = Column(Integer, ForeignKey("books.id"))
    interaction_type = Column(String)  # 'view', 'checkout', 'like'
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
