import asyncio

import pytest
from fastapi import HTTPException

from app.api.dependencies import token as token_dependency


class FakeResponse:
    def __init__(self, status_code: int, body: dict):
        self.status_code = status_code
        self._body = body
        self.content = b"{}"

    def json(self) -> dict:
        return self._body


class FakeClient:
    def __init__(self, response: FakeResponse):
        self.response = response
        self.calls = []

    async def post(self, url: str, **kwargs):
        self.calls.append((url, kwargs))
        return self.response


def test_token_introspection_uses_configured_endpoint(monkeypatch):
    monkeypatch.setattr(
        token_dependency,
        "ASGARDEO_INTROSPECTION_URL",
        "https://api.asgardeo.io/t/gcfprojects/oauth2/introspect",
    )
    monkeypatch.setattr(
        token_dependency,
        "ASGARDEO_INTROSPECTION_CLIENT_ID",
        "client-id",
    )
    monkeypatch.setattr(
        token_dependency,
        "ASGARDEO_INTROSPECTION_CLIENT_SECRET",
        "client-secret",
    )
    client = FakeClient(FakeResponse(200, {"active": True, "scope": "books_read"}))

    metadata = asyncio.run(token_dependency._token_metadata("access-token", client))

    assert metadata["active"] is True
    assert (
        client.calls[0][0]
        == "https://api.asgardeo.io/t/gcfprojects/oauth2/introspect"
    )
    assert client.calls[0][1]["data"] == {"token": "access-token"}
    assert client.calls[0][1]["auth"] == ("client-id", "client-secret")


def test_inactive_introspection_response_rejects_token(monkeypatch):
    monkeypatch.setattr(
        token_dependency,
        "ASGARDEO_INTROSPECTION_CLIENT_ID",
        "client-id",
    )
    monkeypatch.setattr(
        token_dependency,
        "ASGARDEO_INTROSPECTION_CLIENT_SECRET",
        "client-secret",
    )
    client = FakeClient(FakeResponse(200, {"active": False}))

    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(token_dependency._token_metadata("access-token", client))

    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Invalid or expired access token"
