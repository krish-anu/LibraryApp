from fastapi.testclient import TestClient

from app.api.dependencies import verify_access_token


def test_manage_scope_without_admin_role_is_denied_for_admin_routes(client: TestClient, app):
    async def scoped_non_admin(authorization: str = None):  # type: ignore
        return {
            "sub": "member-id",
            "email": "member@example.com",
            "scope": "books_manage books_read",
        }

    app.dependency_overrides[verify_access_token] = scoped_non_admin

    response = client.post(
        "/books/",
        json={
            "title": "Privilege Escalation",
            "author": "QA",
            "category": "Security",
            "description": "",
            "rating": 1,
            "publication_year": 2024,
            "copies_owned": 1,
            "image": "https://example.com/security.jpg",
            "language": "English",
            "pages": 100,
            "rating_count": 0,
        },
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Administrator privileges are required"
