from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.dependencies import get_db
from app.models.users import User as UserModel
from app.pydantic_schemas import user as user_schema

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/{user_id}", response_model=user_schema.User)
def get_user(user_id: str, db: Session = Depends(get_db)):
    """Fetch a user by database `id`."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("/by-member/{member_id}", response_model=user_schema.User)
def get_user_by_member(member_id: str, db: Session = Depends(get_db)):
    """Fetch a user by `member_id` field."""
    user = db.query(UserModel).filter(UserModel.member_id == member_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
