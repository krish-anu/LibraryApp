from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..dependencies import get_db
from ..dependencies import require_admin

router = APIRouter(tags=["general"])


@router.get("/")
def root():
    return {"message": "Hello, FastAPI service is working!"}


@router.get("/test-db")
def test_db(_admin: dict = Depends(require_admin), db: Session = Depends(get_db)):
    result = db.execute(text("SELECT 1")).scalar()
    return {"result": result}
