import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.book import Book
from app.models.category import Category
from app.models.users import User

VALID_BOOK = {
    "title": "Reservable Book",
    "description": "Book for reservations",
    "isbn": "999888777",
    "pageCount": 100,
    "totalCopies": 0,  # Usually reserved when 0 copies available
    "language": "English",
    "publicationYear": 2021,
    "author": "Reserve Author",
}


@pytest.fixture
def member_id(db_session: Session):
    user = User(
        id="res-user-id",
        member_id="M-RES",
        name="Reservation User",
        email="reserve@example.com",
    )
    db_session.add(user)
    db_session.commit()
    return user.id


@pytest.fixture
def book_id(db_session: Session, member_id):
    category = Category(id="reserve-category", name="Reservations")
    book = Book(
        id="reserve-book", title="Reservable Book", category_id=category.id, copies_owned=0
    )
    db_session.add_all([category, book])
    db_session.commit()
    return book.id


@pytest.fixture
def user_headers(app):
    from app.api.dependencies import verify_access_token

    async def mock_user_token(authorization: str = None): # type: ignore
        return {
            "sub": "res-user-id",
            "username": "resuser",
            "groups": [],
            "scope": "reservations_read reservations_manage",
        }

    app.dependency_overrides[verify_access_token] = mock_user_token
    yield {"Authorization": "Bearer res-token"}
    app.dependency_overrides.pop(verify_access_token, None)


def test_reserve_unavailable_book(client: TestClient, book_id, user_headers):
    """RES-01: Reserve unavailable book"""
    payload = {"book_id": book_id, "member_id": "res-user-id"}
    response = client.post("/reservations", json=payload, headers=user_headers)

    assert response.status_code == 201, response.text
    data = response.json()
    assert data["book_id"] == book_id
    assert data["status"] == "pending"


def test_reserve_non_existing_book(client: TestClient, member_id, user_headers):
    """RES-03: Reserve non-existing book"""
    payload = {"book_id": "missing-book", "member_id": member_id}
    response = client.post("/reservations", json=payload, headers=user_headers)
    assert response.status_code == 404


def test_cancel_own_reservation(client: TestClient, book_id, user_headers):
    """RES-11: Cancel own reservation"""
    # Create
    res = client.post(
        "/reservations",
        json={"book_id": book_id, "member_id": "res-user-id"},
        headers=user_headers,
    )
    assert res.status_code == 201, res.text
    reservation_id = res.json()["id"]

    # Cancel
    cancel_res = client.delete(f"/reservations/{reservation_id}", headers=user_headers)
    assert cancel_res.status_code == 200, cancel_res.text

    # Check status is cancelled or deleted
    get_res = client.get(f"/reservations/{reservation_id}", headers=user_headers)
    assert get_res.status_code == 200
    assert get_res.json()["status"] == "cancelled"
