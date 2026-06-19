from datetime import date

from fastapi.testclient import TestClient

from app.dependencies import verify_access_token
from app.models.book import Book
from app.models.category import Category
from app.models.interactions import Interaction
from app.models.users import User


def _override_identity(app, identity: dict):
    async def mock_verify_token(authorization: str = None):  # type: ignore
        return identity

    app.dependency_overrides[verify_access_token] = mock_verify_token


def _seed_user(db_session, user_id: str):
    db_session.add(
        User(
            id=user_id,
            member_id=user_id,
            name=f"User {user_id}",
            email=f"{user_id}@example.com",
            joined_date=date.today(),
        )
    )
    db_session.commit()


def _seed_book(db_session):
    db_session.add(Category(id="cat-security", name="Security", image_url=""))
    db_session.add(
        Book(
            id="book-security",
            title="Security Book",
            category_id="cat-security",
            description="Authz test book",
            rating=0,
            publication_year=2024,
            copies_owned=1,
            image="",
            language="English",
            pages=100,
            rating_count=0,
        )
    )
    db_session.commit()


def test_normal_user_cannot_create_book(client: TestClient, app):
    _override_identity(
        app,
        {
            "sub": "member-a",
            "email": "member-a@example.com",
            "groups": [],
        },
    )

    response = client.post(
        "/books",
        json={
            "title": "Blocked Book",
            "author": "Blocked Author",
            "category": "Blocked",
            "description": "",
            "rating": 0,
            "publication_year": 2024,
            "copies_owned": 1,
            "image": "",
            "language": "English",
            "pages": 100,
            "rating_count": 0,
        },
    )

    assert response.status_code == 403


def test_admin_can_create_book(client: TestClient, app):
    _override_identity(
        app,
        {
            "sub": "admin-a",
            "email": "admin@example.com",
            "groups": ["admin"],
        },
    )

    response = client.post(
        "/books",
        json={
            "title": "Allowed Book",
            "author": "Allowed Author",
            "category": "Allowed",
            "description": "",
            "rating": 0,
            "publication_year": 2024,
            "copies_owned": 1,
            "image": "",
            "language": "English",
            "pages": 100,
            "rating_count": 0,
        },
    )

    assert response.status_code == 201


def test_user_cannot_read_another_user_profile(client: TestClient, app, db_session):
    _seed_user(db_session, "member-a")
    _seed_user(db_session, "member-b")
    _override_identity(
        app,
        {
            "sub": "member-a",
            "email": "member-a@example.com",
            "groups": [],
        },
    )

    response = client.get("/users/member-b")

    assert response.status_code == 403


def test_user_cannot_read_another_user_favorites(client: TestClient, app, db_session):
    _seed_user(db_session, "member-a")
    _seed_user(db_session, "member-b")
    _seed_book(db_session)
    db_session.add(
        Interaction(
            user_id="member-b",
            book_id="book-security",
            interaction_type="like",
        )
    )
    db_session.commit()
    _override_identity(
        app,
        {
            "sub": "member-a",
            "email": "member-a@example.com",
            "groups": [],
        },
    )

    response = client.get("/favorites/member-b")

    assert response.status_code == 403
