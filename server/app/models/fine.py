from .base import Base
from sqlalchemy import Column, TEXT, Date, DateTime, ForeignKey, Numeric
from sqlalchemy.orm import relationship


class Fine(Base):
    __tablename__ = "fines"

    id = Column(TEXT, primary_key=True)
    member_id = Column(TEXT, ForeignKey("users.id"))
    loan_id = Column(TEXT, ForeignKey("loans.id"))
    fine_date = Column(Date)
    fine_amount = Column(Numeric)
    status = Column(TEXT, default="unpaid")
    reason = Column(TEXT)
    due_date = Column(Date)
    paid_at = Column(DateTime)
    payment_method = Column(TEXT)
    created_at = Column(DateTime)
    updated_at = Column(DateTime)

    member = relationship("User")
    loan = relationship("Loan")
