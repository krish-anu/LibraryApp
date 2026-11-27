import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.book import Book
from app.models.category import Category
from app.models.users import User

VALID_BOOK = {
    "title": "Favorite Book",
    "description": "Book for favorites",
    "isbn": "555444333",
    "pageCount": 200,
    "totalCopies": 5,
    "language": "English",
    "publicationYear": 2022,
    "author": "Fav Author",
}


@pytest.fixture
def book_id(db_session: Session):
    user = User(
        id="fav-user-id",
        member_id="M-FAV",
        name="Favorite User",
        email="favorite@example.com",
    )
    category = Category(id="favorite-category", name="Favorites")
    book = Book(
        id="favorite-book",
        title="Favorite Book",
        category_id=category.id,
        copies_owned=1,
    )
    db_session.add_all([user, category, book])
    db_session.commit()
    return book.id


@pytest.fixture
def user_headers(app):
    from app.api.dependencies import verify_access_token

    async def mock_user_token(authorization: str = None): # type: ignore
        return {
            "sub": "fav-user-id",
            "username": "favuser",
            "groups": [],
            "scope": "favorites_read favorites_manage",
        }

    app.dependency_overrides[verify_access_token] = mock_user_token
    yield {"Authorization": "Bearer fav-token"}
    app.dependency_overrides.pop(verify_access_token, None)


def test_add_favorite_valid(client: TestClient, book_id, user_headers):
    """FAV-01: Add favorite valid"""
    response = client.post(
        f"/favorites/fav-user-id/{book_id}", headers=user_headers
    )
    assert response.status_code == 200, response.text
    assert response.json()["is_favorite"] is True


def test_remove_favorite(client: TestClient, book_id, user_headers):
    """FAV-03: Remove existing favorite"""
    add_response = client.post(
        f"/favorites/fav-user-id/{book_id}", headers=user_headers
    )
    assert add_response.status_code == 200

    response = client.delete(
        f"/favorites/fav-user-id/{book_id}", headers=user_headers
    )
    assert response.status_code == 200, response.text
    assert response.json()["is_favorite"] is False


def test_get_own_favorites(client: TestClient, book_id, user_headers):
    """FAV-05: Get own favorites"""
    add_response = client.post(
        f"/favorites/fav-user-id/{book_id}", headers=user_headers
    )
    assert add_response.status_code == 200

    response = client.get("/favorites/fav-user-id", headers=user_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # Check if book_id is in the list
    assert any(b["id"] == book_id for b in data)
