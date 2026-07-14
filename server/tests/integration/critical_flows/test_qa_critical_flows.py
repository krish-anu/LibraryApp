from datetime import date, timedelta

import pytest
from fastapi import HTTPException
from pydantic import ValidationError
from sqlalchemy import func

from app.api.dependencies.authorization import require_subject_or_admin
from app.models.book import Book
from app.models.category import Category
from app.models.fine import Fine
from app.models.fine_payment import FinePayment
from app.models.interactions import Interaction
from app.models.loan import Loan
from app.models.settings import Settings
from app.models.users import User
from app.pydantic_schemas.book import BookCreate
from app.pydantic_schemas.category import CategoryCreate
from app.pydantic_schemas.fine import FineUpdate
from app.pydantic_schemas.reservation import ReservationCreate
from app.pydantic_schemas.settings import SettingsUpdate
from app.routers import category, favorites, fines, loans, reservations, settings
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
    block_on_unpaid_fines=True,
    fine_threshold=10.0,
):
    settings_row = Settings(
        id="settings-qa",
        loan_period_days=loan_period_days,
        max_books_per_user=max_books_per_user,
        block_on_unpaid_fines=block_on_unpaid_fines,
        fine_threshold=fine_threshold,
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
