from sqlalchemy import LargeBinary, VARCHAR, TEXT, Column, Date, DateTime
from .base import Base
from sqlalchemy.orm import relationship
from datetime import datetime


class User(Base):
    __tablename__ = "users"

    id = Column(TEXT, primary_key=True)
    member_id = Column(TEXT)
    name = Column(VARCHAR(100))
    email = Column(VARCHAR(100))
    password = Column(LargeBinary)
    phone = Column(VARCHAR(20), nullable=True)
    address = Column(TEXT, nullable=True)
    profile_image = Column(TEXT, nullable=True)
    joined_date = Column(Date, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
