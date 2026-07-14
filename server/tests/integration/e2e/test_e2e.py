import pytest
from fastapi.testclient import TestClient

from app.models.book import Book
from app.models.users import User

BOOK_PAYLOAD = {
    "title": "E2E Book",
    "description": "Book for E2E flow",
    "category": "Fiction",
    "rating": 4.0,
    "publication_year": 2024,
    "copies_owned": 1,
    "image": "https://example.com/book.jpg",
    "language": "English",
    "pages": 100,
    "rating_count": 10,
    "author": "E2E Author",
}
ALL_TEST_SCOPES = (
    "books_read books_manage loans_read loans_manage "
    "content_read content_manage "
    "favorites_read favorites_manage"
)


@pytest.fixture
def admin_auth(app):
    from app.api.dependencies import verify_access_token

    async def mock_token(authorization: str = None):  # type: ignore
        return {
            "sub": "admin-id",
            "username": "admin",
            "groups": ["admin"],
            "scope": ALL_TEST_SCOPES,
        }

    app.dependency_overrides[verify_access_token] = mock_token
    yield
    app.dependency_overrides.pop(verify_access_token, None)


@pytest.fixture
def user_auth(app):
    from app.api.dependencies import verify_access_token

    async def mock_token(authorization: str = None):  # type: ignore
        return {
            "sub": "user-id",
            "username": "user",
            "groups": [],
            "scope": ALL_TEST_SCOPES,
        }

    app.dependency_overrides[verify_access_token] = mock_token
    yield
    app.dependency_overrides.pop(verify_access_token, None)


def test_successful_borrow_flow(client: TestClient, db_session):
    """E2E-01: Successful borrow flow"""
    from app.api.dependencies import verify_access_token

    # helper override functions
    async def mock_admin_token(authorization: str = None):  # type: ignore
        return {
            "sub": "admin-id",
            "username": "admin",
            "groups": ["admin"],
            "scope": ALL_TEST_SCOPES,
        }

    async def mock_user_token(authorization: str = None):  # type: ignore
        return {
            "sub": "user-id",
            "username": "user",
            "groups": [],
            "scope": ALL_TEST_SCOPES,
        }

    db_session.add(
        User(
            id="user-id",
            member_id="M_E2E",
            name="E2E User",
            email="e2e@example.com",
            phone="0771234567",
            address="Library Street",
        )
    )
    db_session.commit()

    # 1. Admin creates book
    client.app.dependency_overrides[verify_access_token] = mock_admin_token  # type: ignore
    create_res = client.post("/books/", json=BOOK_PAYLOAD)
    assert create_res.status_code == 201, create_res.text

    book_id = create_res.json().get("id", "1")

    # 2. User borrows
    client.app.dependency_overrides[verify_access_token] = mock_user_token  # type: ignore
    borrow_res = client.post(
        "/loans/borrow", params={"book_id": book_id, "member_id": "user-id"}
    )

    assert borrow_res.status_code == 200, borrow_res.text
    assert borrow_res.json()["book_id"] == book_id


def test_favorites_lifecycle(client: TestClient, db_session):
    """E2E-05: Favorites lifecycle"""
    from app.api.dependencies import verify_access_token

    async def mock_user_token(authorization: str = None):  # type: ignore
        return {
            "sub": "user-id",
            "username": "user",
            "groups": [],
            "scope": ALL_TEST_SCOPES,
        }

    client.app.dependency_overrides[verify_access_token] = mock_user_token  # type: ignore

    db_session.add_all(
        [
            User(id="user-id", member_id="M_E2E", name="E2E User", email="e2e@example.com"),
            Book(
                id="favorite-book",
                title="Favorite Book",
                description="",
                rating=0,
                publication_year=2024,
                copies_owned=1,
                image="https://example.com/favorite.jpg",
                language="English",
                pages=100,
                rating_count=0,
            ),
        ]
    )
    db_session.commit()

    add_res = client.post("/favorites/user-id/favorite-book")
    assert add_res.status_code == 200
    assert add_res.json()["is_favorite"] is True

    check_res = client.get("/favorites/user-id/favorite-book/check")
    assert check_res.status_code == 200
    assert check_res.json()["is_favorite"] is True

    remove_res = client.delete("/favorites/user-id/favorite-book")
    assert remove_res.status_code == 200
    assert remove_res.json()["is_favorite"] is False
