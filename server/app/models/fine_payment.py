from .base import Base
from sqlalchemy import Column, TEXT, Date, DateTime, ForeignKey, Numeric
from sqlalchemy.orm import relationship


class FinePayment(Base):
    __tablename__ = "fine_payments"

    id = Column(TEXT, primary_key=True)
    fine_id = Column(TEXT, ForeignKey("fines.id"))
    member_id = Column(TEXT, ForeignKey("users.id"))
    payment_date = Column(Date)
    payment_amount = Column(Numeric)
    payment_method = Column(TEXT)
    handled_by = Column(TEXT)
    notes = Column(TEXT)
    created_at = Column(DateTime)

    fine = relationship("Fine")
    member = relationship("User")
