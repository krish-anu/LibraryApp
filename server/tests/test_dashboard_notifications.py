from datetime import date, datetime, timedelta

from app.models.author import Author
from app.models.book import Book
from app.models.category import Category
from app.models.fine import Fine
from app.models.loan import Loan
from app.models.notification import DeviceToken, Notification
from app.models.users import User
from app.pydantic_schemas.notification import DeviceTokenPayload
from app.routers.dashboard import get_dashboard
from app.routers.notifications import (
    delete_device_token,
    get_notifications,
    get_unread_count,
    read_notification,
    upsert_device_token,
)


def test_dashboard_returns_postgres_aggregates(db_session):
    user = User(
        id="member-1",
        member_id="M001",
        name="Ada Reader",
        email="ada@example.com",
        created_at=datetime.utcnow(),
    )
    author = Author(id="author-1", first_name="Ursula", last_name="Le Guin")
    category = Category(id="category-1", name="Fiction")
    book = Book(
        id="book-1",
        title="The Dispossessed",
        author_id=author.id,
        category_id=category.id,
        copies_owned=4,
    )
    loan = Loan(
        id="loan-1",
        book_id=book.id,
        member_id=user.id,
        loan_date=date.today(),
        returned_date=date.today() + timedelta(days=14),
    )
    fine = Fine(
        id="fine-1",
        member_id=user.id,
        loan_id=loan.id,
        fine_date=date.today(),
        fine_amount=7.5,
        status="unpaid",
        reason="Overdue",
        created_at=datetime.utcnow(),
    )
    db_session.add_all([user, author, category, book, loan, fine])
    db_session.commit()

    data = get_dashboard(_admin={}, db=db_session)
    assert data["stats"]["activeUsers"] == 1
    assert data["stats"]["totalInventory"] == 4
    assert data["stats"]["pendingFines"] == 7.5
    assert data["stats"]["fineCount"] == 1
    assert data["stats"]["avgCheckoutTime"] == 14
    assert data["topBooks"] == [
        {"id": "book-1", "title": "The Dispossessed", "count": 1}
    ]
    assert data["recentFines"][0]["users"]["name"] == "Ada Reader"


def test_admin_notification_list_and_read(db_session):
    admin_notification = Notification(
        id="notification-admin",
        title="Book borrowed",
        body="A member borrowed a book.",
        category="borrowed",
        recipient_type="admin",
    )
    user_notification = Notification(
        id="notification-user",
        title="Borrow successful",
        body="Your book is due soon.",
        category="borrowed",
        recipient_type="user",
        recipient_id="member-1",
    )
    db_session.add_all([admin_notification, user_notification])
    db_session.commit()

    identity = {"sub": "admin-user-id", "groups": ["admin"]}
    listed = get_notifications(limit=6, identity=identity, db=db_session)
    assert [item["id"] for item in listed] == ["notification-admin"]

    count = get_unread_count(identity=identity, db=db_session)
    assert count == {"unread": 1}

    marked = read_notification(
        "notification-admin", identity=identity, db=db_session
    )
    assert marked["read"] is True

    count = get_unread_count(identity=identity, db=db_session)
    assert count == {"unread": 0}


def test_device_token_is_upserted_for_authenticated_user(db_session):
    identity = {"sub": "test-user-id"}
    payload = DeviceTokenPayload(token="device-token-1", platform="android")

    created = upsert_device_token(payload, identity=identity, db=db_session)
    assert created["platform"] == "android"

    updated = upsert_device_token(
        DeviceTokenPayload(token="device-token-1", platform="ios"),
        identity=identity,
        db=db_session,
    )
    assert updated["platform"] == "ios"
    assert db_session.query(DeviceToken).count() == 1

    deleted = delete_device_token(
        payload,
        identity=identity,
        db=db_session,
    )
    assert deleted == {"success": True, "marked": 1}
