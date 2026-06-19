from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..dependencies import get_db, require_admin, verify_access_token
from ..models import category
from ..pydantic_schemas import category as category_schema

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=List[category_schema.Category])
def get_categories(
    _identity: dict = Depends(verify_access_token), db: Session = Depends(get_db)
):
    return db.query(category.Category).all()


@router.post("", response_model=category_schema.Category, status_code=201)
def create_category(
    data: category_schema.CategoryCreate,
    _admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
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


@router.get("/{category_id}", response_model=category_schema.Category)
def get_category(
    category_id: str,
    _identity: dict = Depends(verify_access_token),
    db: Session = Depends(get_db),
):
    cat = (
        db.query(category.Category).filter(category.Category.id == category_id).first()
    )
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    return cat


@router.put("/{category_id}", response_model=category_schema.Category)
def update_category(
    category_id: str,
    data: category_schema.CategoryCreate,
    _admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
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


@router.delete("/{category_id}", status_code=204)
def delete_category(
    category_id: str,
    _admin: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
    cat = (
        db.query(category.Category).filter(category.Category.id == category_id).first()
    )
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    db.delete(cat)
    db.commit()
    return None
