from .base import Base
from sqlalchemy import Column, TEXT
from sqlalchemy.orm import relationship


class Author(Base):
    __tablename__ = "authors"

    id = Column(TEXT, primary_key=True)
    first_name = Column(TEXT)
    last_name = Column(TEXT)

    books = relationship("Book", back_populates="author_rel")
