import asyncio
from datetime import date

import pytest
from fastapi import HTTPException

from app.api.dependencies import identity_is_admin, require_admin_scope
from app.models.users import User
from app.pydantic_schemas.fine import FineCreate, FineUpdate
from app.routers.auth import debug_identity
from app.routers.fines import (
    create_fine,
    get_fine,
    get_member_fine_summary,
    list_fines,
    list_member_fines,
    update_fine,
)
from app.routers.users import list_users


def test_admin_policy_requires_admin_role_by_default(monkeypatch):
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
    assert (
        identity_is_admin({"sub": "admin", "roles": {"Next.js": ["admin"]}}) is True
    )

    monkeypatch.setenv("ADMIN_EMAILS", "testadmin@example.com")
    assert identity_is_admin({"sub": "admin", "email": "testadmin@example.com"}) is True

    monkeypatch.setenv("ADMIN_SUBJECTS", "admin-subject-id")
    assert identity_is_admin({"sub": "admin-subject-id"}) is True


def test_auth_debug_identity_reports_safe_admin_claims(monkeypatch):
    monkeypatch.setenv("ADMIN_GROUPS", "admin")
    response = asyncio.run(
        debug_identity(
            {
                "sub": "admin-user-id",
                "email": "admin@example.com",
                "groups": ["admin"],
                "scope": "openid profile books:manage",
                "_access_token": "secret-token",
            }
        )
    )

    body = response.model_dump()
    assert body["is_admin"] is True
    assert body["subject_present"] is True
    assert body["matched_admin_values"] == ["admin"]
    assert "groups" in body["role_claim_keys_present"]
    assert "books:manage" in body["scopes_seen"]
    assert "books_manage" in body["scopes_seen"]
    assert "secret-token" not in response.model_dump_json()
    assert "admin@example.com" not in response.model_dump_json()


def test_admin_scope_allows_scope_with_admin_role_claim(monkeypatch):
    monkeypatch.setenv("ADMIN_GROUPS", "admin")
    checker = require_admin_scope("books_manage")

    identity = asyncio.run(
        checker(
            {
                "sub": "admin-user-id",
                "groups": ["admin"],
                "scope": "books_manage",
            }
        )
    )

    assert identity["sub"] == "admin-user-id"


def test_admin_scope_rejects_missing_scope_after_admin_role_claim(monkeypatch):
    monkeypatch.setenv("ADMIN_GROUPS", "admin")
    checker = require_admin_scope("books_manage")

    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            checker(
                {
                    "sub": "admin-user-id",
                    "groups": ["admin"],
                    "scope": "books_read",
                }
            )
        )

    assert exc_info.value.status_code == 403
    assert exc_info.value.detail == "Missing required scope: books_manage"


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


def test_member_can_read_own_fines_and_summary(db_session):
    db_session.add_all(
        [
            User(id="u1", member_id="M001", name="Ada Reader", email="ada@example.com"),
            User(id="u2", member_id="M002", name="Grace Hopper", email="grace@example.com"),
        ]
    )
    db_session.commit()

    create_fine(
        FineCreate(
            member_id="u1",
            fine_amount=10,
            fine_date=date.today(),
            reason="Overdue",
        ),
        _admin={},
        db=db_session,
    )
    create_fine(
        FineCreate(
            member_id="u2",
            fine_amount=20,
            fine_date=date.today(),
            reason="Overdue",
        ),
        _admin={},
        db=db_session,
    )

    identity = {"sub": "u1", "scope": "fines_read"}
    summary = get_member_fine_summary("u1", identity=identity, db=db_session)
    listed = list_member_fines(
        "u1",
        page=1,
        limit=10,
        identity=identity,
        db=db_session,
    )

    assert summary == {"member_id": "u1", "total_due": 10.0, "unpaid_count": 1}
    assert listed["total_due"] == 10.0
    assert listed["totalCount"] == 1
    assert listed["data"][0]["member_id"] == "u1"


def test_member_cannot_read_another_members_fine(db_session):
    db_session.add(
        User(id="u2", member_id="M002", name="Grace Hopper", email="grace@example.com")
    )
    db_session.commit()
    created = create_fine(
        FineCreate(
            member_id="u2",
            fine_amount=20,
            fine_date=date.today(),
            reason="Overdue",
        ),
        _admin={},
        db=db_session,
    )

    with pytest.raises(HTTPException) as exc_info:
        get_fine(
            created["data"]["id"],
            identity={"sub": "u1", "scope": "fines_read"},
            db=db_session,
        )

    assert exc_info.value.status_code == 403
