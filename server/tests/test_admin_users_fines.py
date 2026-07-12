from datetime import date

import pytest
from fastapi import HTTPException

from app.api.dependencies import identity_is_admin, require_admin_scope
from app.models.users import User
from app.pydantic_schemas.fine import FineCreate, FineUpdate
from app.routers.auth import debug_identity
from app.routers.fines import create_fine, list_fines, update_fine
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


@pytest.mark.asyncio
async def test_auth_debug_identity_reports_safe_admin_claims(monkeypatch):
    monkeypatch.setenv("ADMIN_GROUPS", "admin")
    response = await debug_identity(
        {
            "sub": "admin-user-id",
            "email": "admin@example.com",
            "groups": ["admin"],
            "scope": "openid profile books:manage",
            "_access_token": "secret-token",
        }
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


@pytest.mark.asyncio
async def test_admin_scope_allows_scope_without_role_claim(monkeypatch):
    monkeypatch.setenv("ADMIN_GROUPS", "admin")
    checker = require_admin_scope("books_manage")

    identity = await checker({"sub": "admin-user-id", "scope": "books_manage"})

    assert identity["sub"] == "admin-user-id"


@pytest.mark.asyncio
async def test_admin_scope_rejects_missing_scope_before_role_claim(monkeypatch):
    monkeypatch.setenv("ADMIN_GROUPS", "admin")
    checker = require_admin_scope("books_manage")

    with pytest.raises(HTTPException) as exc_info:
        await checker({"sub": "admin-user-id", "scope": "books_read"})

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
