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
        # Older seeded rows stored paths relative to the repository root.
        # Flutter assets are relative to the client package, so normalize the
        # legacy prefix before validating or returning the API response.
        if cleaned.startswith("client/assets/"):
            cleaned = cleaned.removeprefix("client/")
        if cleaned.startswith(("https://", "assets/", "/assets/")):
            return cleaned
        raise ValueError("image must be an HTTPS URL or local asset path")


class BookCreate(BookBase):
    pass


class Book(BookBase):
    id: str

    model_config = ConfigDict(from_attributes=True)
