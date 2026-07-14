from unittest.mock import AsyncMock, MagicMock, patch

from fastapi.testclient import TestClient


def _response(status_code, body):
    mock_resp = MagicMock()
    mock_resp.status_code = status_code
    mock_resp.content = b"{}"
    mock_resp.json.return_value = body
    return mock_resp


def test_login_invalid_credentials_returns_unauthorized(client: TestClient):
    payload = {"email": "wrong@example.com", "password": "bad-password"}

    with patch("app.routers.auth.ASGARDEO_PUBLIC_CLIENT_ID", "test-public"), patch(
        "app.routers.auth.ASGARDEO_BASE_URL", "https://api.asgardeo.io/t/test"
    ), patch("httpx.AsyncClient") as mock_http_client:
        http_instance = AsyncMock()
        mock_http_client.return_value.__aenter__.return_value = http_instance

        async def post(url, *args, **kwargs):
            if url.endswith("/oauth2/authorize/"):
                return _response(
                    200,
                    {
                        "flowId": "flow-123",
                        "nextStep": {
                            "authenticators": [
                                {
                                    "authenticatorId": "basic",
                                    "requiredParams": ["username", "password"],
                                }
                            ]
                        },
                    },
                )
            if url.endswith("/oauth2/authn"):
                return _response(401, {"error_description": "Invalid credentials"})
            raise AssertionError(f"Unexpected POST URL: {url}")

        http_instance.post.side_effect = post

        response = client.post("/auth/login/credentials", json=payload)

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid credentials"


def test_login_requires_configured_public_client_id(client: TestClient):
    payload = {"email": "valid@example.com", "password": "valid-password"}

    with patch("app.routers.auth.ASGARDEO_PUBLIC_CLIENT_ID", ""), patch(
        "app.routers.auth.ASGARDEO_BASE_URL", "https://api.asgardeo.io/t/test"
    ):
        response = client.post("/auth/login/credentials", json=payload)

    assert response.status_code == 500
    assert "ASGARDEO_PUBLIC_CLIENT_ID" in response.json()["detail"]
