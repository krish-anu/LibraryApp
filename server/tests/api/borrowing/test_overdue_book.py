from datetime import date, timedelta

from fastapi.testclient import TestClient

from app.models.book import Book
from app.models.loan import Loan
from app.models.users import User


def test_overdue_book_displays_active_loan_with_past_due_date(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    overdue_date = date.today() - timedelta(days=3)
    db_session.add_all(
        [
            User(id="test-user-id", member_id="MTEST", name="Borrower", email="b@example.com"),
            Book(id="overdue-book", title="Overdue", copies_owned=0),
            Loan(
                id="loan-overdue",
                book_id="overdue-book",
                member_id="test-user-id",
                loan_date=date.today() - timedelta(days=20),
                returned_date=overdue_date,
                status="active",
            ),
        ]
    )
    db_session.commit()

    response = client.get("/loans/active", params={"member_id": "test-user-id"})

    assert response.status_code == 200
    body = response.json()
    assert body[0]["id"] == "loan-overdue"
    assert body[0]["returned_date"] == overdue_date.isoformat()
