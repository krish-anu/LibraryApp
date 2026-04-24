from typing import Optional

from pydantic import BaseModel, ConfigDict


class CategoryBase(BaseModel):
    name: str
    image_url: Optional[str] = None


class CategoryCreate(CategoryBase):
    image_url: str = ""


class Category(CategoryBase):
    id: str

    model_config = ConfigDict(from_attributes=True)
