from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class BlogPostBase(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    excerpt: str = Field(default="", max_length=600)
    content: str = Field(default="", max_length=20000)
    author: str = Field(default="Library Team", min_length=1, max_length=120)
    category: str = Field(default="Library", min_length=1, max_length=80)
    cover_image: str | None = Field(default=None, max_length=2048)
    read_minutes: int = Field(default=3, ge=1, le=180)
    published: bool = True
    published_at: datetime | None = None


class BlogPostCreate(BlogPostBase):
    pass


class BlogPost(BlogPostBase):
    id: str
    published_at: datetime

    model_config = ConfigDict(from_attributes=True)


class VideoPostBase(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str = Field(default="", max_length=3000)
    youtube_video_id: str = Field(min_length=6, max_length=32)
    speaker: str = Field(default="Library Team", min_length=1, max_length=120)
    category: str = Field(default="Learning", min_length=1, max_length=80)
    duration: str = Field(default="", max_length=40)
    thumbnail_url: str | None = Field(default=None, max_length=2048)
    published: bool = True
    published_at: datetime | None = None

    @field_validator("youtube_video_id")
    @classmethod
    def validate_youtube_video_id(cls, value: str) -> str:
        cleaned = value.strip()
        allowed = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        if not cleaned or any(char not in allowed for char in cleaned):
            raise ValueError("youtube_video_id must contain only YouTube video id characters")
        return cleaned


class VideoPostCreate(VideoPostBase):
    pass


class VideoPost(VideoPostBase):
    id: str
    published_at: datetime

    model_config = ConfigDict(from_attributes=True)
