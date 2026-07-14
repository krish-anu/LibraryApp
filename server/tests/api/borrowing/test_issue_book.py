from datetime import date

from fastapi.testclient import TestClient

from app.models.book import Book
from app.models.users import User


def test_issue_book_decrements_inventory(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add_all(
        [
            User(
                id="test-user-id",
                member_id="MTEST",
                name="Borrower",
                email="borrower@example.com",
                phone="0771234567",
                address="Library Street",
                joined_date=date.today(),
            ),
            Book(
                id="borrow-book",
                title="Borrowable",
                description="",
                rating=0,
                publication_year=2024,
                copies_owned=2,
                image="https://example.com/borrow.jpg",
                language="English",
                pages=100,
                rating_count=0,
            ),
        ]
    )
    db_session.commit()

    response = client.post(
        "/loans/borrow",
        params={"book_id": "borrow-book", "member_id": "test-user-id"},
    )

    assert response.status_code == 200
    assert response.json()["book_id"] == "borrow-book"
    db_session.refresh(db_session.get(Book, "borrow-book"))
    assert db_session.get(Book, "borrow-book").copies_owned == 1


def test_issue_book_requires_contact_details(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add_all(
        [
            User(id="test-user-id", member_id="MTEST", name="Borrower", email="b@example.com"),
            Book(id="borrow-book", title="Borrowable", copies_owned=1),
        ]
    )
    db_session.commit()

    response = client.post(
        "/loans/borrow",
        params={"book_id": "borrow-book", "member_id": "test-user-id"},
    )

    assert response.status_code == 400
    assert "mobile number and address" in response.json()["detail"]
