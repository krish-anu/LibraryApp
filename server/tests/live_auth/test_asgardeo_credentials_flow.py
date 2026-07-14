import os

import pytest
from fastapi.testclient import TestClient


pytestmark = pytest.mark.live_auth


def _required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        pytest.fail(f"Missing required live auth environment variable: {name}")
    return value


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _error_body(response) -> str:
    try:
        return str(response.json())
    except Exception:
        return response.text


def _required_scopes(name: str, default: str) -> set[str]:
    raw = os.getenv(name, default)
    return {part.strip() for part in raw.replace(",", " ").split() if part.strip()}


def _assert_required_scopes(identity_body: dict, required: set[str]) -> None:
    scopes_seen = set(identity_body.get("scopes_seen") or [])
    missing = required.difference(scopes_seen)
    assert not missing, f"Missing scopes {sorted(missing)} from {sorted(scopes_seen)}"


def _login_with_credentials(
    client: TestClient, email_env: str, password_env: str
) -> tuple[str, str]:
    response = client.post(
        "/auth/login/credentials",
        json={
            "email": _required_env(email_env),
            "password": _required_env(password_env),
        },
    )
    assert response.status_code == 200, _error_body(response)

    body = response.json()
    token = body.get("access_token")
    assert token, "Credential login response did not include access_token"
    assert body.get("success") is True
    user_id = body.get("user", {}).get("id")
    assert user_id
    return token, user_id


def test_live_admin_credentials_token_scopes_and_protected_settings(
    client: TestClient,
):
    _required_env("ASGARDEO_BASE_URL")
    _required_env("ASGARDEO_PUBLIC_CLIENT_ID")

    token, admin_subject = _login_with_credentials(
        client, "E2E_ADMIN_EMAIL", "E2E_ADMIN_PASSWORD"
    )
    os.environ.setdefault("ADMIN_SUBJECTS", admin_subject)

    identity_response = client.get("/auth/debug/identity", headers=_bearer(token))
    assert identity_response.status_code == 200, _error_body(identity_response)
    identity_body = identity_response.json()
    assert identity_body["subject_present"] is True
    assert identity_body["is_admin"] is True
    _assert_required_scopes(
        identity_body,
        _required_scopes(
            "E2E_REQUIRED_ADMIN_SCOPES",
            "settings_read settings_manage books_read users_read",
        ),
    )

    settings_response = client.get("/settings/", headers=_bearer(token))
    assert settings_response.status_code == 200, _error_body(settings_response)

    update_response = client.patch(
        "/settings/",
        json={"loan_period_days": 14, "max_books_per_user": 5},
        headers=_bearer(token),
    )
    assert update_response.status_code == 200, _error_body(update_response)


def test_live_member_credentials_token_scopes_and_admin_denial(
    client: TestClient,
):
    _required_env("ASGARDEO_BASE_URL")
    _required_env("ASGARDEO_PUBLIC_CLIENT_ID")

    token, _member_subject = _login_with_credentials(
        client, "E2E_MEMBER_EMAIL", "E2E_MEMBER_PASSWORD"
    )

    identity_response = client.get("/auth/debug/identity", headers=_bearer(token))
    assert identity_response.status_code == 200, _error_body(identity_response)
    identity_body = identity_response.json()
    assert identity_body["subject_present"] is True
    assert identity_body["is_admin"] is False
    _assert_required_scopes(
        identity_body,
        _required_scopes("E2E_REQUIRED_MEMBER_SCOPES", "books_read"),
    )

    books_response = client.get("/books/", headers=_bearer(token))
    assert books_response.status_code == 200, _error_body(books_response)

    users_response = client.get("/users/", headers=_bearer(token))
    assert users_response.status_code == 403
