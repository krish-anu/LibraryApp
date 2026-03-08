from fastapi import APIRouter,Depends
from ..models.category import Category
from sqlalchemy.orm import Session
from ..dependencies import get_db, verify_access_token
from ..models import category

router=APIRouter(prefix="/category",tags=["categories"], dependencies=[Depends(verify_access_token)])

@router.get("")
def getCategories(db:Session=Depends(get_db)):
    categories=db.query(category.Category).all()
    return categories 