from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


class CategoryBase(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    image_url: Optional[str] = Field(default=None, max_length=2048)

    @field_validator("image_url")
    @classmethod
    def validate_image_url(cls, value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = value.strip()
        if not cleaned:
            return ""
        if cleaned.startswith(("https://", "assets/", "/assets/")):
            return cleaned
        raise ValueError("image_url must be an HTTPS URL or local asset path")


class CategoryCreate(CategoryBase):
    image_url: str = ""


class Category(CategoryBase):
    id: str

    model_config = ConfigDict(from_attributes=True)
