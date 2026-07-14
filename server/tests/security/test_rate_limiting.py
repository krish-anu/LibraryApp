from types import SimpleNamespace

from app.core.security import client_identifier, create_limiter


class DummyRequest:
    def __init__(self, host: str, headers: dict[str, str] | None = None):
        self.client = SimpleNamespace(host=host)
        self.headers = headers or {}


def test_rate_limit_identifier_uses_client_host_by_default(monkeypatch):
    monkeypatch.setenv("TRUST_PROXY_HEADERS", "false")

    request = DummyRequest("10.0.0.5", {"x-forwarded-for": "203.0.113.10"})

    assert client_identifier(request) == "10.0.0.5"


def test_rate_limit_identifier_uses_trusted_proxy_forwarded_for(monkeypatch):
    monkeypatch.setenv("TRUST_PROXY_HEADERS", "true")
    monkeypatch.setenv("TRUSTED_PROXY_CIDRS", "10.0.0.0/24")

    request = DummyRequest("10.0.0.5", {"x-forwarded-for": "203.0.113.10, 10.0.0.5"})

    assert client_identifier(request) == "203.0.113.10"


def test_limiter_can_be_created_with_default_limits():
    limiter = create_limiter(["2/minute"])

    assert limiter is not None
