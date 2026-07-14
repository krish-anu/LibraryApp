import asyncio

import pytest
from fastapi import HTTPException

from app.api.dependencies import require_admin_scope, require_scope
from app.api.dependencies.identity import identity_has_any_scope, identity_scopes


def test_scope_claims_accept_space_colon_and_underscore_formats():
    identity = {
        "scope": "books:read settings_read",
        "permissions": ["loans:manage", "favorites_manage"],
    }

    assert "books_read" in identity_scopes(identity)
    assert identity_has_any_scope(identity, ["books_read"]) is True
    assert identity_has_any_scope(identity, ["loans_manage"]) is True
    assert identity_has_any_scope(identity, ["settings_read"]) is True


def test_missing_scope_returns_forbidden():
    checker = require_scope("books_manage")

    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(checker({"sub": "member-1", "scope": "books_read"}))

    assert exc_info.value.status_code == 403
    assert exc_info.value.detail == "Missing required scope: books_manage"


def test_admin_endpoint_requires_role_and_scope(monkeypatch):
    monkeypatch.setenv("ADMIN_GROUPS", "admin")
    checker = require_admin_scope("settings_manage")

    with pytest.raises(HTTPException) as no_role:
        asyncio.run(checker({"sub": "member-1", "scope": "settings_manage"}))
    assert no_role.value.status_code == 403
    assert no_role.value.detail == "Administrator privileges are required"

    with pytest.raises(HTTPException) as no_scope:
        asyncio.run(checker({"sub": "admin-1", "groups": ["admin"], "scope": "settings_read"}))
    assert no_scope.value.status_code == 403
    assert no_scope.value.detail == "Missing required scope: settings_manage"

    identity = asyncio.run(
        checker({"sub": "admin-1", "groups": ["admin"], "scope": "settings_manage"})
    )
    assert identity["sub"] == "admin-1"
