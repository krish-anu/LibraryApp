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


def _scopes_seen(identity_body: dict) -> set[str]:
    return set(identity_body.get("scopes_seen") or [])


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


def test_live_admin_credentials_are_rejected_by_mobile_login(
    client: TestClient,
):
    _required_env("ASGARDEO_BASE_URL")
    _required_env("ASGARDEO_PUBLIC_CLIENT_ID")

    response = client.post(
        "/auth/login/credentials",
        json={
            "email": _required_env("E2E_ADMIN_EMAIL"),
            "password": _required_env("E2E_ADMIN_PASSWORD"),
        },
    )
    assert response.status_code == 403, _error_body(response)
    assert response.json()["detail"] == (
        "Administrator accounts can only sign in to the admin portal."
    )


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
    scopes = _scopes_seen(identity_body)
    assert {"openid", "profile"}.issubset(scopes)

    books_response = client.get("/books/", headers=_bearer(token))
    expected_books_status = 200 if "books_read" in scopes else 403
    assert books_response.status_code == expected_books_status, _error_body(
        books_response
    )

    users_response = client.get("/users/", headers=_bearer(token))
    assert users_response.status_code == 403
