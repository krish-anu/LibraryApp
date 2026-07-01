from .base import Base
from sqlalchemy import Column, TEXT, Date, ForeignKey
from sqlalchemy.orm import relationship
from .book import Book
from .users import User


class Loan(Base):
    __tablename__ = "loans"

    id = Column(TEXT, primary_key=True)
    book_id = Column(TEXT, ForeignKey("books.id"))
    member_id = Column(TEXT, ForeignKey("users.id"))
    loan_date = Column(Date)
    returned_date = Column(Date)
    status = Column(TEXT, default="active")
    returned_at = Column(Date, nullable=True)
    returned_by = Column(TEXT, nullable=True)

    book = relationship(Book)
    member = relationship(User)
