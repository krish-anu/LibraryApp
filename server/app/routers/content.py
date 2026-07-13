from datetime import datetime
from typing import List
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import (
    get_db,
    identity_is_admin,
    require_admin_scope,
    require_scope,
)
from ..models.content import BlogPost, VideoPost
from ..pydantic_schemas import content as content_schema

router = APIRouter(tags=["content"])


def _published_blog_query(db: Session):
    return (
        db.query(BlogPost)
        .filter(BlogPost.published.is_(True))
        .order_by(BlogPost.published_at.desc())
    )


def _published_video_query(db: Session):
    return (
        db.query(VideoPost)
        .filter(VideoPost.published.is_(True))
        .order_by(VideoPost.published_at.desc())
    )


@router.get("/blogs", response_model=List[content_schema.BlogPost])
def get_blogs(
    include_unpublished: bool = Query(default=False),
    identity: dict = Depends(require_scope("books_read")),
    db: Session = Depends(get_db),
):
    if include_unpublished:
        if not identity_is_admin(identity):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Administrator privileges are required",
            )
        return db.query(BlogPost).order_by(BlogPost.published_at.desc()).all()
    return _published_blog_query(db).all()


@router.get("/blogs/{blog_id}", response_model=content_schema.BlogPost)
def get_blog(
    blog_id: str,
    include_unpublished: bool = Query(default=False),
    identity: dict = Depends(require_scope("books_read")),
    db: Session = Depends(get_db),
):
    query = (
        db.query(BlogPost)
        if include_unpublished and identity_is_admin(identity)
        else _published_blog_query(db)
    )
    blog = query.filter(BlogPost.id == blog_id).first()
    if not blog:
        raise HTTPException(status_code=404, detail="Blog not found")
    return blog


@router.post(
    "/blogs",
    response_model=content_schema.BlogPost,
    status_code=status.HTTP_201_CREATED,
)
def create_blog(
    data: content_schema.BlogPostCreate,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    blog = BlogPost(
        id=str(uuid4()),
        title=data.title,
        excerpt=data.excerpt,
        content=data.content,
        url=data.url,
        author=data.author,
        source=data.source,
        category=data.category,
        tags=data.tags,
        language=data.language,
        featured=data.featured,
        status=data.status,
        sort_order=data.sort_order,
        cover_image=data.cover_image,
        read_minutes=data.read_minutes,
        published=data.published,
        published_at=data.published_at or datetime.utcnow(),
    )
    db.add(blog)
    db.commit()
    db.refresh(blog)
    return blog


@router.put("/blogs/{blog_id}", response_model=content_schema.BlogPost)
def update_blog(
    blog_id: str,
    data: content_schema.BlogPostCreate,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    blog = db.query(BlogPost).filter(BlogPost.id == blog_id).first()
    if not blog:
        raise HTTPException(status_code=404, detail="Blog not found")

    blog.title = data.title
    blog.excerpt = data.excerpt
    blog.content = data.content
    blog.url = data.url
    blog.author = data.author
    blog.source = data.source
    blog.category = data.category
    blog.tags = data.tags
    blog.language = data.language
    blog.featured = data.featured
    blog.status = data.status
    blog.sort_order = data.sort_order
    blog.cover_image = data.cover_image
    blog.read_minutes = data.read_minutes
    blog.published = data.published
    blog.published_at = data.published_at or blog.published_at
    db.commit()
    db.refresh(blog)
    return blog


@router.delete("/blogs/{blog_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_blog(
    blog_id: str,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    blog = db.query(BlogPost).filter(BlogPost.id == blog_id).first()
    if not blog:
        raise HTTPException(status_code=404, detail="Blog not found")
    db.delete(blog)
    db.commit()
    return None


@router.get("/videos", response_model=List[content_schema.VideoPost])
def get_videos(
    include_unpublished: bool = Query(default=False),
    identity: dict = Depends(require_scope("books_read")),
    db: Session = Depends(get_db),
):
    if include_unpublished:
        if not identity_is_admin(identity):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Administrator privileges are required",
            )
        return db.query(VideoPost).order_by(VideoPost.published_at.desc()).all()
    return _published_video_query(db).all()


@router.get("/videos/{video_id}", response_model=content_schema.VideoPost)
def get_video(
    video_id: str,
    include_unpublished: bool = Query(default=False),
    identity: dict = Depends(require_scope("books_read")),
    db: Session = Depends(get_db),
):
    query = (
        db.query(VideoPost)
        if include_unpublished and identity_is_admin(identity)
        else _published_video_query(db)
    )
    video = query.filter(VideoPost.id == video_id).first()
    if not video:
        raise HTTPException(status_code=404, detail="Video not found")
    return video


@router.post(
    "/videos",
    response_model=content_schema.VideoPost,
    status_code=status.HTTP_201_CREATED,
)
def create_video(
    data: content_schema.VideoPostCreate,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    video = VideoPost(
        id=str(uuid4()),
        title=data.title,
        description=data.description,
        youtube_video_id=data.youtube_video_id,
        youtube_url=data.youtube_url,
        speaker=data.speaker,
        channel_name=data.channel_name,
        category=data.category,
        tags=data.tags,
        duration=data.duration,
        thumbnail_url=data.thumbnail_url,
        language=data.language,
        featured=data.featured,
        status=data.status,
        sort_order=data.sort_order,
        published=data.published,
        published_at=data.published_at or datetime.utcnow(),
    )
    db.add(video)
    db.commit()
    db.refresh(video)
    return video


@router.put("/videos/{video_id}", response_model=content_schema.VideoPost)
def update_video(
    video_id: str,
    data: content_schema.VideoPostCreate,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    video = db.query(VideoPost).filter(VideoPost.id == video_id).first()
    if not video:
        raise HTTPException(status_code=404, detail="Video not found")

    video.title = data.title
    video.description = data.description
    video.youtube_video_id = data.youtube_video_id
    video.youtube_url = data.youtube_url
    video.speaker = data.speaker
    video.channel_name = data.channel_name
    video.category = data.category
    video.tags = data.tags
    video.duration = data.duration
    video.thumbnail_url = data.thumbnail_url
    video.language = data.language
    video.featured = data.featured
    video.status = data.status
    video.sort_order = data.sort_order
    video.published = data.published
    video.published_at = data.published_at or video.published_at
    db.commit()
    db.refresh(video)
    return video


@router.delete("/videos/{video_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_video(
    video_id: str,
    _admin: dict = Depends(require_admin_scope("books_manage")),
    db: Session = Depends(get_db),
):
    video = db.query(VideoPost).filter(VideoPost.id == video_id).first()
    if not video:
        raise HTTPException(status_code=404, detail="Video not found")
    db.delete(video)
    db.commit()
    return None
