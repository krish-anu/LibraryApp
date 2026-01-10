from sqlalchemy import LargeBinary, VARCHAR, TEXT, Column
from .base import Base
from sqlalchemy.orm import relationship


class User(Base):
    __tablename__ = "users"

    id = Column(TEXT, primary_key=True)
    member_id = Column(TEXT)
    name = Column(VARCHAR(100))
    email = Column(VARCHAR(100))
    password = Column(LargeBinary)
