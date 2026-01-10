from .base import Base
from sqlalchemy import Column, TEXT, Date, ForeignKey
from sqlalchemy.orm import relationship


class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(TEXT, primary_key=True)
    book_id = Column(TEXT, ForeignKey("books.id"))
    member_id = Column(TEXT, ForeignKey("users.id"))
    reservation_date = Column(Date)
    status = Column(TEXT)

    book = relationship("Book")
    member = relationship("User")
