from pydantic import BaseModel, ConfigDict
from datetime import date
from typing import Optional


class LoanBase(BaseModel):
    book_id: str
    member_id: str
    loan_date: date
    returned_date: Optional[date] = None
    status: str = "active"
    returned_at: Optional[date] = None
    returned_by: Optional[str] = None


class LoanCreate(LoanBase):
    pass


class Loan(LoanBase):
    id: str

    model_config = ConfigDict(from_attributes=True)
