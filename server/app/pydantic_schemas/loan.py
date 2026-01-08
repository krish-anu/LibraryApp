from pydantic import BaseModel
from datetime import date
from typing import Optional


class LoanBase(BaseModel):
    book_id: str
    member_id: str
    loan_date: date
    returned_date: Optional[date] = None


class LoanCreate(LoanBase):
    pass


class Loan(LoanBase):
    id: str

    class Config:
        from_attributes = True
