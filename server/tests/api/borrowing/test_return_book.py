from datetime import date, timedelta

from fastapi.testclient import TestClient

from app.models.book import Book
from app.models.loan import Loan
from app.models.users import User


def test_return_book_restores_inventory_once(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add_all(
        [
            User(id="test-user-id", member_id="MTEST", name="Borrower", email="b@example.com"),
            Book(id="return-book", title="Returnable", copies_owned=0),
            Loan(
                id="loan-return",
                book_id="return-book",
                member_id="test-user-id",
                loan_date=date.today(),
                returned_date=date.today() + timedelta(days=14),
                status="active",
            ),
        ]
    )
    db_session.commit()

    response = client.post(
        "/loans/return/loan-return", json={"returned_by": "Front Desk"}
    )

    assert response.status_code == 200
    assert response.json()["status"] == "Returned"
    assert db_session.get(Book, "return-book").copies_owned == 1

    duplicate = client.post("/loans/return/loan-return")
    assert duplicate.status_code == 409
    assert db_session.get(Book, "return-book").copies_owned == 1
