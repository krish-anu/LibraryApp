from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from ..dependencies import get_db, verify_access_token
from ..models import category

router = APIRouter(
    prefix="/categories",
    tags=["categories"],
    dependencies=[Depends(verify_access_token)],
)


class CategoryCreate(BaseModel):
    name: str
    image_url: str = ""


@router.get("")
def getCategories(db: Session = Depends(get_db)):
    categories = db.query(category.Category).all()
    return categories


@router.post("")
def createCategory(data: CategoryCreate, db: Session = Depends(get_db)):
    existing = (
        db.query(category.Category).filter(category.Category.name == data.name).first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Category already exists")

    new_category = category.Category(
        id=f"cat_{data.name.lower().replace(' ', '_')}",
        name=data.name,
        image_url=data.image_url or None,
    )
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category


@router.get("/{category_id}")
def getCategory(category_id: str, db: Session = Depends(get_db)):
    cat = (
        db.query(category.Category).filter(category.Category.id == category_id).first()
    )
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    return cat


@router.put("/{category_id}")
def updateCategory(
    category_id: str, data: CategoryCreate, db: Session = Depends(get_db)
):
    cat = (
        db.query(category.Category).filter(category.Category.id == category_id).first()
    )
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")

    cat.name = data.name
    cat.image_url = data.image_url or None

    db.commit()
    db.refresh(cat)
    return cat


@router.put("/{category_id}")
def updateCategory(
    category_id: str, data: CategoryCreate, db: Session = Depends(get_db)
):
    cat = (
        db.query(category.Category).filter(category.Category.id == category_id).first()
    )
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")

    cat.name = data.name
    cat.description = data.description

    db.commit()
    db.refresh(cat)
    return cat


@router.delete("/{category_id}", status_code=204)
def deleteCategory(category_id: str, db: Session = Depends(get_db)):
    cat = (
        db.query(category.Category).filter(category.Category.id == category_id).first()
    )
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    db.delete(cat)
    db.commit()
    return None
