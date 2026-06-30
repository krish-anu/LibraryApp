from datetime import date

from app.dependencies import identity_is_admin
from app.models.users import User
from app.pydantic_schemas.fine import FineCreate, FineUpdate
from app.routers.fines import create_fine, list_fines, update_fine
from app.routers.users import list_users


def test_admin_policy_requires_admin_role_by_default(monkeypatch):
    monkeypatch.delenv("ADMIN_EMAILS", raising=False)
    monkeypatch.delenv("ADMIN_GROUPS", raising=False)
    assert identity_is_admin({"sub": "portal-user"}) is False
    assert identity_is_admin({"sub": "member", "groups": ["user"]}) is False
    assert identity_is_admin({"sub": "admin", "groups": ["admin"]}) is True

    monkeypatch.setenv("ADMIN_GROUPS", "admin")
    assert identity_is_admin({"sub": "member", "groups": []}) is False
    assert identity_is_admin({"sub": "admin", "groups": ["admin"]}) is True
    assert (
        identity_is_admin(
            {"sub": "admin", "http://wso2.org/claims/roles": ["admin"]}
        )
        is True
    )
    assert (
        identity_is_admin({"sub": "admin", "http://wso2.org/claims/role": "admin"})
        is True
    )
    assert identity_is_admin({"sub": "admin", "applicationRoles": ["admin"]}) is True
    assert identity_is_admin({"sub": "admin", "roles": ["Next.js/admin"]}) is True
    assert identity_is_admin({"sub": "admin", "roles": [{"display": "admin"}]}) is True

    monkeypatch.setenv("ADMIN_EMAILS", "admin@gmail.com")
    assert identity_is_admin({"sub": "admin", "username": "admin@gmail.com"}) is True


def test_user_collection_is_paginated_and_searchable(db_session):
    db_session.add_all(
        [
            User(id="u1", member_id="M001", name="Ada Reader", email="ada@example.com"),
            User(id="u2", member_id="M002", name="Grace Hopper", email="grace@example.com"),
        ]
    )
    db_session.commit()

    result = list_users(
        page=1,
        limit=10,
        search="Grace",
        _admin={},
        db=db_session,
    )

    assert result["totalCount"] == 1
    assert result["data"][0].id == "u2"


def test_fine_collection_and_physical_payment(db_session):
    db_session.add(
        User(id="u1", member_id="M001", name="Ada Reader", email="ada@example.com")
    )
    db_session.commit()

    created = create_fine(
        FineCreate(
            member_id="u1",
            fine_amount=10,
            fine_date=date.today(),
            reason="Overdue",
        ),
        _admin={},
        db=db_session,
    )
    fine_id = created["data"]["id"]

    listed = list_fines(
        page=1,
        limit=10,
        search="Ada",
        status="unpaid",
        _admin={},
        db=db_session,
    )
    assert listed["totalCount"] == 1
    assert listed["data"][0]["fine_amount"] == 10

    updated = update_fine(
        fine_id,
        FineUpdate(payment_amount=4, payment_method="physical"),
        admin={"sub": "admin-1"},
        db=db_session,
    )
    assert updated["payment"] == {"appliedAmount": 4.0, "remainingAmount": 6.0}
    assert updated["data"]["total_paid"] == 4
    assert updated["data"]["fine_amount"] == 6
