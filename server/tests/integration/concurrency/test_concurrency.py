from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

from fastapi import HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.models.book import Book
from app.models.loan import Loan
from app.models.settings import Settings
from app.models.users import User
from app.routers.loans import borrow_book


def test_concurrent_borrows_of_different_books_honor_member_limit(db_session):
    member_id = "concurrent-member"
    db_session.add_all(
        [
            User(
                id=member_id,
                member_id=member_id,
                email="concurrent@example.com",
                phone="0771234567",
                address="Main Street",
            ),
            Settings(id="concurrency-settings", max_books_per_user=1),
            Book(id="first-book", title="First Book", copies_owned=1),
            Book(id="second-book", title="Second Book", copies_owned=1),
        ]
    )
    db_session.commit()

    engine = db_session.get_bind()
    start = Barrier(2, timeout=10)

    def borrow(book_id):
        with Session(engine) as db:
            db.execute(text("SET LOCAL lock_timeout = '5s'"))
            start.wait()
            try:
                borrow_book(book_id, member_id, identity={"sub": member_id}, db=db)
            except HTTPException as error:
                assert error.status_code == 400
                assert "Borrowing limit reached" in error.detail
                return False
            return True

    with ThreadPoolExecutor(max_workers=2) as executor:
        outcomes = list(executor.map(borrow, ("first-book", "second-book")))

    assert outcomes.count(True) == 1
    loan = db_session.query(Loan).filter_by(member_id=member_id, status="active").one()
    assert db_session.get(Book, loan.book_id).copies_owned == 0
    assert sum(book.copies_owned for book in db_session.query(Book)) == 1
