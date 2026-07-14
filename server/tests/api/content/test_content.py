from datetime import datetime

from app.api.dependencies import verify_access_token
from app.models.content import BlogPost, VideoPost


def _override_identity(app, identity: dict):
    async def mock_verify_token(authorization: str = None):  # type: ignore
        return identity

    app.dependency_overrides[verify_access_token] = mock_verify_token


def test_get_blogs_returns_published_posts(client, db_session, override_auth_dependency):
    db_session.add_all(
        [
            BlogPost(
                id="published-blog",
                title="Reading Room Notes",
                excerpt="A short update",
                content="Fresh picks from the reading room.",
                author="Library Team",
                category="Library",
                read_minutes=2,
                published=True,
                published_at=datetime(2026, 1, 2),
            ),
            BlogPost(
                id="draft-blog",
                title="Draft",
                excerpt="Hidden",
                content="Not ready",
                author="Library Team",
                category="Library",
                read_minutes=2,
                published=False,
                published_at=datetime(2026, 1, 3),
            ),
        ]
    )
    db_session.commit()

    response = client.get("/blogs", headers={"Authorization": "Bearer test-token"})

    assert response.status_code == 200
    payload = response.json()
    assert [blog["id"] for blog in payload] == ["published-blog"]
    assert payload[0]["title"] == "Reading Room Notes"


def test_get_videos_returns_published_videos(client, db_session, override_auth_dependency):
    db_session.add_all(
        [
            VideoPost(
                id="published-video",
                title="Library Walkthrough",
                description="How to use the app",
                youtube_video_id="ysz5S6PUM-U",
                speaker="Library Team",
                category="Guide",
                duration="2:50",
                published=True,
                published_at=datetime(2026, 1, 2),
            ),
            VideoPost(
                id="draft-video",
                title="Draft Video",
                description="Hidden",
                youtube_video_id="dQw4w9WgXcQ",
                speaker="Library Team",
                category="Guide",
                duration="3:32",
                published=False,
                published_at=datetime(2026, 1, 3),
            ),
        ]
    )
    db_session.commit()

    response = client.get("/videos", headers={"Authorization": "Bearer test-token"})

    assert response.status_code == 200
    payload = response.json()
    assert [video["id"] for video in payload] == ["published-video"]
    assert payload[0]["youtube_video_id"] == "ysz5S6PUM-U"


def test_blog_read_requires_content_scope(client, app):
    _override_identity(
        app,
        {
            "sub": "test-user-id",
            "email": "test@example.com",
            "scope": "books_read",
        },
    )

    response = client.get("/blogs", headers={"Authorization": "Bearer test-token"})

    assert response.status_code == 403
    assert response.json()["detail"] == "Missing required scope: content_read"
