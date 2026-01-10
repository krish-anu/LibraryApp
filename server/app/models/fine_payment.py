from .base import Base
from sqlalchemy import Column, TEXT, Date, ForeignKey, Numeric
from sqlalchemy.orm import relationship


class FinePayment(Base):
    __tablename__ = "fine_payments"

    id = Column(TEXT, primary_key=True)
    member_id = Column(TEXT, ForeignKey("users.id"))
    payment_date = Column(Date)
    payment_amount = Column(Numeric)

    member = relationship("User")
