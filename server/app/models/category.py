from .base import Base
from sqlalchemy import Column, TEXT
from sqlalchemy.orm import relationship


class Category(Base):
    __tablename__ = "categories"

    id = Column(TEXT, primary_key=True)
    name = Column(TEXT)
    image_url = Column(TEXT)

    books = relationship("Book", back_populates="category_rel")
 