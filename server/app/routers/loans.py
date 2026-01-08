from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from ..dependencies import get_db
from ..models import loan
from ..pydantic_schemas import loan as loan_schema

router = APIRouter(prefix="/loans", tags=["loans"])


@router.get("", response_model=List[loan_schema.Loan])
def get_loans(db: Session = Depends(get_db)):
    return db.query(loan.Loan).all()
