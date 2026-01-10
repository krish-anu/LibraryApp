from .base import Base
from sqlalchemy import Column, TEXT, Date, ForeignKey, Numeric
from sqlalchemy.orm import relationship


class Fine(Base):
    __tablename__ = "fines"

    id = Column(TEXT, primary_key=True)
    member_id = Column(TEXT, ForeignKey("users.id"))
    loan_id = Column(TEXT, ForeignKey("loans.id"))
    fine_date = Column(Date)
    fine_amount = Column(Numeric)

    member = relationship("User")
    loan = relationship("Loan")
