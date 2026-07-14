from datetime import date, timedelta

from fastapi.testclient import TestClient

from app.models.book import Book
from app.models.loan import Loan
from app.models.users import User


def test_renew_active_loan_extends_due_date(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    old_due = date.today() + timedelta(days=2)
    db_session.add_all(
        [
            User(id="test-user-id", member_id="MTEST", name="Borrower", email="b@example.com"),
            Book(id="renew-book", title="Renewable", copies_owned=0),
            Loan(
                id="loan-renew",
                book_id="renew-book",
                member_id="test-user-id",
                loan_date=date.today(),
                returned_date=old_due,
                status="active",
            ),
        ]
    )
    db_session.commit()

    response = client.post("/loans/renew/loan-renew")

    assert response.status_code == 200
    assert response.json()["returned_date"] > old_due.isoformat()


def test_returned_loan_cannot_be_renewed(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add_all(
        [
            User(id="test-user-id", member_id="MTEST", name="Borrower", email="b@example.com"),
            Book(id="renew-returned-book", title="Returned", copies_owned=1),
            Loan(
                id="loan-returned-renew",
                book_id="renew-returned-book",
                member_id="test-user-id",
                loan_date=date.today(),
                returned_date=date.today(),
                status="returned",
            ),
        ]
    )
    db_session.commit()

    response = client.post("/loans/renew/loan-returned-renew")

    assert response.status_code == 409
