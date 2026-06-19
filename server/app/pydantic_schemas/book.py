from datetime import date

from pydantic import BaseModel, ConfigDict, Field, field_validator


class BookBase(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    author: str = Field(min_length=1, max_length=200)
    category: str = Field(min_length=1, max_length=100)
    description: str = Field(default="", max_length=5000)
    rating: float = Field(default=0.0, ge=0, le=5)
    publication_year: int = Field(default=0, ge=0, le=date.today().year + 1)
    copies_owned: int = Field(default=0, ge=0, le=10000)
    image: str = Field(default="", max_length=2048)
    language: str = Field(default="English", min_length=1, max_length=80)
    pages: int = Field(default=200, ge=1, le=10000)
    rating_count: int = Field(default=0, ge=0)

    @field_validator("image")
    @classmethod
    def validate_image_url(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            return cleaned
        if cleaned.startswith(("https://", "assets/", "/assets/")):
            return cleaned
        raise ValueError("image must be an HTTPS URL or local asset path")


class BookCreate(BookBase):
    pass


class Book(BookBase):
    id: str

    model_config = ConfigDict(from_attributes=True)
