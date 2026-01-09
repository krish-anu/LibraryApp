from fastapi import APIRouter,Depends
from ..models.category import Category
from sqlalchemy.orm import Session
from ..dependencies import get_db
from ..models import category

router=APIRouter(prefix="/category",tags=["categories"])

@router.get("/")
def getCategories(db:Session=Depends(get_db)):
    categories=db.query(category.Category).all()
    return categories 