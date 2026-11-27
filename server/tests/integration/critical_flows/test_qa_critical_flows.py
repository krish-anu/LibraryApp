from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta
from decimal import Decimal
from threading import Barrier

import pytest
from fastapi import HTTPException
from pydantic import ValidationError
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.dependencies.authorization import require_subject_or_admin
from app.models.book import Book
from app.models.category import Category
from app.models.fine import Fine
from app.models.fine_payment import FinePayment
from app.models.interactions import Interaction
from app.models.loan import Loan
from app.models.reservation import Reservation
from app.models.settings import Settings
from app.models.users import User
from app.pydantic_schemas.book import BookCreate
from app.pydantic_schemas.category import CategoryCreate
from app.pydantic_schemas.fine import FineCreate, FineUpdate
from app.pydantic_schemas.reservation import ReservationCreate
from app.pydantic_schemas.settings import SettingsUpdate
from app.routers import (
    books,
    category,
    favorites,
    fines,
    loans,
    reservations,
    settings,
    users as users_router,
)
from app.services.images import validate_image_body


def _seed_member(db_session, user_id="member-1", *, phone="0771234567", address="Main Street"):
    user = User(
        id=user_id,
        member_id=user_id,
        name=f"Member {user_id}",
        email=f"{user_id}@example.com",
        phone=phone,
        address=address,
        joined_date=date.today(),
    )
    db_session.add(user)
    db_session.commit()
    return user


def _seed_book(db_session, book_id="book-1", *, copies=2, category_id="cat-qa"):
    category_row = db_session.get(Category, category_id)
    if category_row is None:
        category_row = Category(id=category_id, name="QA Category", image_url="")
        db_session.add(category_row)
        db_session.flush()

    book = Book(
        id=book_id,
        title=f"QA Book {book_id}",
        category_id=category_row.id,
        description="A book used by QA automation.",
        rating=4.5,
        publication_year=2024,
        copies_owned=copies,
        image="",
        language="English",
        pages=240,
        rating_count=12,
    )
    db_session.add(book)
    db_session.commit()
    return book


def _seed_settings(
    db_session,
    *,
    loan_period_days=14,
    max_books_per_user=5,
    max_renewals=1,
    block_on_unpaid_fines=True,
    fine_threshold=10.0,
    grace_period_days=2,
    daily_fine_rate=0.5,
    max_fine_cap=25.0,
):
    settings_row = Settings(
        id="settings-qa",
        loan_period_days=loan_period_days,
        max_books_per_user=max_books_per_user,
        max_renewals=max_renewals,
        block_on_unpaid_fines=block_on_unpaid_fines,
        fine_threshold=fine_threshold,
        grace_period_days=grace_period_days,
        daily_fine_rate=daily_fine_rate,
        max_fine_cap=max_fine_cap,
    )
    db_session.add(settings_row)
    db_session.commit()
    return settings_row


def _book_payload(**overrides):
    payload = {
        "title": "Valid QA Book",
        "author": "QA Author",
        "category": "QA Category",
        "description": "Created by automated QA.",
        "rating": 4.0,
        "publication_year": 2024,
        "copies_owned": 3,
        "image": "",
        "language": "English",
        "pages": 300,
        "rating_count": 1,
    }
    payload.update(overrides)
    return payload


def _assert_http_error(status_code, callback):
    with pytest.raises(HTTPException) as exc_info:
        callback()
    assert exc_info.value.status_code == status_code
    return exc_info.value


def _race_transactions(db_session, *operations):
    engine = db_session.get_bind()
    barrier = Barrier(len(operations), timeout=10)

    def run(operation):
        with Session(engine) as transaction:
            barrier.wait()
            try:
                operation(transaction)
            except HTTPException as error:
                return error.status_code
            return 200

    with ThreadPoolExecutor(max_workers=len(operations)) as executor:
        return sorted(executor.map(run, operations))


def test_book_create_schema_rejects_invalid_boundaries():
    invalid_cases = [
        {"title": ""},
        {"rating": 5.1},
        {"rating": -0.1},
        {"copies_owned": -1},
        {"copies_owned": 10001},
        {"pages": 0},
        {"pages": 10001},
        {"image": "javascript:alert(1)"},
    ]

    for override in invalid_cases:
        with pytest.raises(ValidationError), pytest.MonkeyPatch.context():
            BookCreate(**_book_payload(**override))


def test_book_image_validation_rejects_mismatched_magic_bytes():
    error = _assert_http_error(
        415,
        lambda: validate_image_body(b"not really a png", "image/png"),
    )

    assert error.detail == "Image bytes do not match the Content-Type"


def test_category_duplicate_name_is_rejected(db_session):
    db_session.add(Category(id="cat-existing", name="Existing", image_url=""))
    db_session.commit()

    error = _assert_http_error(
        400,
        lambda: category.create_category(
            CategoryCreate(name="Existing", image_url=""),
            _admin={},
            db=db_session,
        ),
    )

    assert error.detail == "Category already exists"


def test_settings_defaults_and_boundary_validation(db_session):
    result = settings.get_settings(_identity={}, db=db_session)

    assert result.loan_period_days == 14
    assert db_session.query(Settings).count() == 1

    with pytest.raises(ValidationError):
        SettingsUpdate(loan_period_days=0)


def test_borrow_success_decrements_inventory_and_sets_due_date(db_session):
    _seed_settings(db_session, loan_period_days=21)
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=2)

    result = loans.borrow_book(
        "book-1",
        "member-1",
        identity={"sub": "member-1"},
        db=db_session,
    )

    assert result.book_id == "book-1"
    assert result.member_id == "member-1"
    assert result.status == "active"
    assert result.returned_date == date.today() + timedelta(days=21)
    assert int(db_session.get(Book, "book-1").copies_owned) == 1


def test_only_one_member_can_borrow_the_last_copy_concurrently(db_session):
    _seed_member(db_session, "member-1")
    _seed_member(db_session, "member-2")
    _seed_book(db_session, copies=1)

    def borrow(member_id, db):
        return loans.borrow_book(
            "book-1", member_id, identity={"sub": member_id}, db=db
        )

    assert _race_transactions(
        db_session,
        lambda db: borrow("member-1", db),
        lambda db: borrow("member-2", db),
    ) == [200, 400]
    assert db_session.get(Book, "book-1").copies_owned == 0
    assert db_session.query(Loan).filter_by(book_id="book-1", status="active").count() == 1


def test_failed_loan_insert_rolls_back_inventory_and_reservation(db_session, monkeypatch):
    _seed_member(db_session, "member-1")
    _seed_book(db_session, copies=1)
    db_session.add_all([
        Loan(
            id="existing-loan",
            book_id="book-1",
            member_id="member-1",
            loan_date=date.today() - timedelta(days=2),
            returned_at=date.today() - timedelta(days=1),
            status="returned",
        ),
        Reservation(
            id="reserved-copy",
            book_id="book-1",
            member_id="member-1",
            reservation_date=date.today(),
            status="ready",
        ),
    ])
    db_session.commit()
    monkeypatch.setattr(loans, "uuid4", lambda: "existing-loan")

    _assert_http_error(
        409,
        lambda: loans.borrow_book(
            "book-1", "member-1", identity={"sub": "member-1"}, db=db_session
        ),
    )

    with Session(db_session.get_bind()) as observer:
        assert observer.get(Book, "book-1").copies_owned == 1
        assert observer.get(Reservation, "reserved-copy").status == "ready"
        assert observer.query(Loan).filter_by(status="active").count() == 0


def test_borrow_requires_phone_and_address(db_session):
    _seed_settings(db_session)
    _seed_member(db_session, "member-1", phone="", address="")
    _seed_book(db_session, "book-1", copies=1)

    error = _assert_http_error(
        400,
        lambda: loans.borrow_book(
            "book-1",
            "member-1",
            identity={"sub": "member-1"},
            db=db_session,
        ),
    )

    assert "mobile number and address" in error.detail
    assert db_session.query(Loan).count() == 0
    assert int(db_session.get(Book, "book-1").copies_owned) == 1


def test_borrow_blocks_duplicate_active_loan_without_changing_inventory(db_session):
    _seed_settings(db_session)
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=2)
    db_session.add(
        Loan(
            id="loan-existing",
            book_id="book-1",
            member_id="member-1",
            loan_date=date.today(),
            returned_date=date.today() + timedelta(days=14),
            status="active",
        )
    )
    db_session.commit()

    error = _assert_http_error(
        409,
        lambda: loans.borrow_book(
            "book-1",
            "member-1",
            identity={"sub": "member-1"},
            db=db_session,
        ),
    )

    assert "already borrowed" in error.detail
    assert int(db_session.get(Book, "book-1").copies_owned) == 2


def test_borrow_blocks_member_at_max_active_loans(db_session):
    _seed_settings(db_session, max_books_per_user=1)
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-active", copies=1)
    _seed_book(db_session, "book-new", copies=1)
    db_session.add(
        Loan(
            id="loan-active",
            book_id="book-active",
            member_id="member-1",
            loan_date=date.today(),
            returned_date=date.today() + timedelta(days=14),
            status="active",
        )
    )
    db_session.commit()

    error = _assert_http_error(
        400,
        lambda: loans.borrow_book(
            "book-new",
            "member-1",
            identity={"sub": "member-1"},
            db=db_session,
        ),
    )

    assert "Borrowing limit reached" in error.detail
    assert int(db_session.get(Book, "book-new").copies_owned) == 1


def test_borrow_blocks_unpaid_fines_at_threshold(db_session):
    _seed_settings(db_session, fine_threshold=10.0)
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=1)
    db_session.add(
        Fine(
            id="fine-threshold",
            member_id="member-1",
            fine_date=date.today(),
            fine_amount=10.0,
            status="unpaid",
            reason="Boundary fine",
        )
    )
    db_session.commit()

    error = _assert_http_error(
        400,
        lambda: loans.borrow_book(
            "book-1",
            "member-1",
            identity={"sub": "member-1"},
            db=db_session,
        ),
    )

    assert "Borrowing blocked due to unpaid fines" in error.detail
    assert int(db_session.get(Book, "book-1").copies_owned) == 1


def test_return_is_idempotency_safe_for_duplicate_submission(db_session):
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=0)
    db_session.add(
        Loan(
            id="loan-1",
            book_id="book-1",
            member_id="member-1",
            loan_date=date.today(),
            returned_date=date.today() + timedelta(days=14),
            status="active",
        )
    )
    db_session.commit()

    first = loans.return_book(
        "loan-1",
        loans.ReturnBookPayload(returned_by="Desk"),
        identity={"sub": "member-1"},
        db=db_session,
    )
    second = _assert_http_error(
        409,
        lambda: loans.return_book(
            "loan-1",
            loans.ReturnBookPayload(returned_by="Desk"),
            identity={"sub": "member-1"},
            db=db_session,
        ),
    )

    assert first["status"] == "Returned"
    assert second.detail == "Loan is already returned"
    assert int(db_session.get(Book, "book-1").copies_owned) == 1


def test_overdue_return_creates_one_capped_settings_based_fine(db_session):
    _seed_settings(
        db_session,
        grace_period_days=2,
        daily_fine_rate=1.5,
        max_fine_cap=10.0,
    )
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=0)
    db_session.add(
        Loan(
            id="loan-overdue",
            book_id="book-1",
            member_id="member-1",
            loan_date=date.today() - timedelta(days=30),
            returned_date=date.today() - timedelta(days=12),
            status="active",
        )
    )
    db_session.commit()

    result = loans.return_book(
        "loan-overdue",
        loans.ReturnBookPayload(returned_by="Desk"),
        identity={"sub": "member-1"},
        db=db_session,
    )

    generated = db_session.query(Fine).filter(Fine.loan_id == "loan-overdue").one()
    assert result["fine_created"] is True
    assert result["fine_amount"] == 10.0
    assert float(generated.fine_amount) == 10.0
    assert generated.status == "unpaid"


def test_renewal_limit_and_waiting_member_are_enforced(db_session):
    _seed_settings(db_session, max_renewals=1)
    _seed_member(db_session, "member-1")
    _seed_member(db_session, "member-2")
    _seed_book(db_session, "book-1", copies=0)
    loan = Loan(
        id="loan-renew",
        book_id="book-1",
        member_id="member-1",
        loan_date=date.today(),
        returned_date=date.today() + timedelta(days=5),
        status="active",
    )
    db_session.add(loan)
    db_session.commit()

    renewed = loans.renew_loan(
        "loan-renew", identity={"sub": "member-1"}, db=db_session
    )
    assert renewed.renewal_count == 1
    limit_error = _assert_http_error(
        409,
        lambda: loans.renew_loan(
            "loan-renew", identity={"sub": "member-1"}, db=db_session
        ),
    )
    assert "Renewal limit reached" in limit_error.detail

    loan.renewal_count = 0
    db_session.add(
        Reservation(
            id="reservation-waiting",
            book_id="book-1",
            member_id="member-2",
            reservation_date=date.today(),
            status="pending",
        )
    )
    db_session.commit()
    waiting_error = _assert_http_error(
        409,
        lambda: loans.renew_loan(
            "loan-renew", identity={"sub": "member-1"}, db=db_session
        ),
    )
    assert "another member is waiting" in waiting_error.detail


def test_reservation_duplicate_active_record_is_rejected(db_session):
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=0)
    payload = ReservationCreate(
        book_id="book-1",
        member_id="member-1",
        reservation_date=date.today().isoformat(),
        status="pending",
    )

    first = reservations.create_reservation(payload, identity={"sub": "member-1"}, db=db_session)
    second = _assert_http_error(
        409,
        lambda: reservations.create_reservation(
            payload,
            identity={"sub": "member-1"},
            db=db_session,
        ),
    )

    assert first.book_id == "book-1"
    assert "already reserved" in second.detail


def test_returned_history_does_not_block_reservation(db_session):
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=0)
    db_session.add(
        Loan(
            id="loan-returned",
            book_id="book-1",
            member_id="member-1",
            loan_date=date.today() - timedelta(days=20),
            returned_date=date.today() - timedelta(days=6),
            returned_at=date.today() - timedelta(days=7),
            status="returned",
        )
    )
    db_session.commit()

    result = reservations.create_reservation(
        ReservationCreate(book_id="book-1", member_id="member-1"),
        identity={"sub": "member-1"},
        db=db_session,
    )

    assert result.status == "pending"


def test_available_book_cannot_be_reserved(db_session):
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=1)

    error = _assert_http_error(
        409,
        lambda: reservations.create_reservation(
            ReservationCreate(book_id="book-1", member_id="member-1"),
            identity={"sub": "member-1"},
            db=db_session,
        ),
    )

    assert "available to borrow" in error.detail


def test_return_and_cancel_promote_reservations_in_queue_order(db_session, monkeypatch):
    _seed_member(db_session, "borrower")
    _seed_member(db_session, "member-first")
    _seed_member(db_session, "member-second")
    _seed_book(db_session, copies=0)
    db_session.add(
        Loan(
            id="loan-to-return",
            book_id="book-1",
            member_id="borrower",
            loan_date=date.today(),
            returned_date=date.today(),
            status="active",
        )
    )
    db_session.commit()
    ids = iter(["z-first", "a-second"])
    monkeypatch.setattr(reservations, "uuid4", lambda: next(ids))

    first = reservations.create_reservation(
        ReservationCreate(book_id="book-1", member_id="member-first"),
        identity={"sub": "member-first"},
        db=db_session,
    )
    second = reservations.create_reservation(
        ReservationCreate(
            book_id="book-1",
            member_id="member-second",
            reservation_date=(date.today() - timedelta(days=1)).isoformat(),
        ),
        identity={"sub": "member-second"},
        db=db_session,
    )
    loans.return_book("loan-to-return", identity={"sub": "borrower"}, db=db_session)
    assert first.status == "ready"
    assert second.status == "pending"
    _assert_http_error(
        409,
        lambda: loans.borrow_book(
            "book-1", "member-second", identity={"sub": "member-second"}, db=db_session
        ),
    )
    db_session.rollback()

    reservations.cancel_reservation(
        first.id, identity={"sub": "member-first"}, db=db_session
    )
    assert first.status == "cancelled"
    assert second.status == "ready"
    loans.borrow_book(
        "book-1", "member-second", identity={"sub": "member-second"}, db=db_session
    )
    assert second.status == "fulfilled"
    assert db_session.get(Book, "book-1").copies_owned == 0


def test_profile_stats_count_only_active_records(db_session):
    _seed_member(db_session, "member-1")
    _seed_book(db_session, "book-1", copies=0)
    _seed_book(db_session, "book-2", copies=0, category_id="cat-qa")
    db_session.add_all(
        [
            Loan(
                id="loan-active",
                book_id="book-1",
                member_id="member-1",
                loan_date=date.today(),
                returned_date=date.today() + timedelta(days=14),
                status="active",
            ),
            Loan(
                id="loan-returned",
                book_id="book-2",
                member_id="member-1",
                loan_date=date.today() - timedelta(days=20),
                returned_date=date.today() - timedelta(days=6),
                returned_at=date.today() - timedelta(days=7),
                status="returned",
            ),
            Reservation(
                id="reservation-active",
                book_id="book-1",
                member_id="member-1",
                reservation_date=date.today(),
                status="pending",
            ),
            Reservation(
                id="reservation-cancelled",
                book_id="book-2",
                member_id="member-1",
                reservation_date=date.today(),
                status="cancelled",
            ),
        ]
    )
    db_session.commit()

    stats = users_router.get_user_stats(
        "member-1", identity={"sub": "member-1"}, db=db_session
    )

    assert stats.total_borrows == 2
    assert stats.books_read == 1
    assert stats.active_loans == 1
    assert stats.active_reservations == 1


def test_book_create_persists_author_relationship(db_session):
    created = books.create_book(
        BookCreate(**_book_payload(author="Ada Lovelace")),
        _admin={},
        db=db_session,
    )

    assert created.author == "Ada Lovelace"
    stored = db_session.get(Book, created.id)
    assert stored.author_id is not None
    assert stored.author == "Ada Lovelace"


@pytest.mark.parametrize("amount", ["0.001", "1.234", "NaN", "Infinity"])
def test_fine_amounts_require_finite_whole_cents(amount):
    with pytest.raises(ValidationError):
        FineCreate(member_id="member-1", fine_date=date.today(), fine_amount=amount)
    with pytest.raises(ValidationError):
        FineUpdate(payment_amount=amount)


def test_concurrent_payments_cannot_overpay_the_same_fine(db_session):
    _seed_member(db_session)
    db_session.add(
        Fine(
            id="fine-concurrent",
            member_id="member-1",
            fine_date=date.today(),
            fine_amount=Decimal("0.30"),
            status="unpaid",
        )
    )
    db_session.commit()

    def pay(db):
        return fines.update_fine(
            "fine-concurrent",
            FineUpdate(payment_amount=Decimal("0.20")),
            admin={"sub": "admin-1"},
            db=db,
        )

    assert _race_transactions(db_session, pay, pay) == [200, 400]
    fine = db_session.get(Fine, "fine-concurrent")
    assert fine.fine_amount == Decimal("0.10")
    assert fine.status == "unpaid"
    payment = db_session.query(FinePayment).filter_by(fine_id=fine.id).one()
    assert payment.payment_amount == Decimal("0.20")


def test_fine_partial_full_and_overpayment_flow(db_session):
    _seed_member(db_session, "member-1")
    db_session.add(
        Fine(
            id="fine-1",
            member_id="member-1",
            fine_date=date.today(),
            fine_amount=100.0,
            status="unpaid",
            reason="Manual fine",
        )
    )
    db_session.commit()

    partial = fines.update_fine(
        "fine-1",
        FineUpdate(payment_amount=30, payment_method="physical", notes="cash"),
        admin={"sub": "admin-1"},
        db=db_session,
    )
    overpay = _assert_http_error(
        400,
        lambda: fines.update_fine(
            "fine-1",
            FineUpdate(payment_amount=70.01),
            admin={"sub": "admin-1"},
            db=db_session,
        ),
    )
    full = fines.update_fine(
        "fine-1",
        FineUpdate(payment_amount=70),
        admin={"sub": "admin-1"},
        db=db_session,
    )

    assert partial["payment"] == {"appliedAmount": 30.0, "remainingAmount": 70.0}
    assert "Payment exceeds" in overpay.detail
    assert full["data"]["status"] == "paid"
    fine = db_session.get(Fine, "fine-1")
    assert float(fine.fine_amount) == 0
    assert db_session.query(FinePayment).filter(FinePayment.fine_id == "fine-1").count() == 2


def test_favorite_add_is_idempotent_and_subject_protected(db_session):
    _seed_member(db_session, "member-1")
    _seed_member(db_session, "member-2")
    _seed_book(db_session, "book-1")

    first = favorites.add_favorite(
        "member-1",
        "book-1",
        identity={"sub": "member-1"},
        db=db_session,
    )
    second = favorites.add_favorite(
        "member-1",
        "book-1",
        identity={"sub": "member-1"},
        db=db_session,
    )
    blocked = _assert_http_error(
        403,
        lambda: favorites.get_favorites(
            "member-2",
            identity={"sub": "member-1"},
            db=db_session,
        ),
    )

    assert first["is_favorite"] is True
    assert second["message"] == "Book already in favorites"
    assert blocked.detail == "You are not allowed to access this resource"
    assert (
        db_session.query(func.count(Interaction.id))
        .filter(
            Interaction.user_id == "member-1",
            Interaction.book_id == "book-1",
            Interaction.interaction_type == "like",
        )
        .scalar()
        == 1
    )


def test_subject_or_admin_authorization_blocks_cross_member_access():
    error = _assert_http_error(
        403,
        lambda: require_subject_or_admin({"sub": "member-1"}, "member-2"),
    )

    assert error.detail == "You are not allowed to access this resource"

    require_subject_or_admin({"sub": "member-1"}, "member-1")
    require_subject_or_admin({"sub": "admin-1", "groups": ["admin"]}, "member-2")
