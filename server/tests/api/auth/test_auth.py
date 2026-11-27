import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock, AsyncMock

@pytest.fixture(autouse=True)
def mock_env_vars():
    with patch("app.routers.auth.ASGARDEO_M2M_CLIENT_ID", "test-client"), \
         patch("app.routers.auth.ASGARDEO_M2M_CLIENT_SECRET", "test-secret"), \
         patch("app.routers.auth.ASGARDEO_PUBLIC_CLIENT_ID", "test-public"), \
         patch("app.routers.auth.ASGARDEO_PUBLIC_CLIENT_SECRET", ""), \
         patch("app.api.dependencies.token.ASGARDEO_INTROSPECTION_CLIENT_ID", "test-public"), \
         patch("app.api.dependencies.token.ASGARDEO_INTROSPECTION_CLIENT_SECRET", "test-secret"), \
         patch("app.api.dependencies.token.ASGARDEO_BASE_URL", "https://api.asgardeo.io/t/test"), \
         patch("app.routers.auth.ASGARDEO_BASE_URL", "https://api.asgardeo.io/t/test"):
        yield

def test_register_valid_user(client: TestClient):
    """AUTH-01: Register valid user"""
    payload = {
        "email": "newuser@example.com",
        "username": "newuser",
        "password": "StrongPassword123!",
        "first_name": "New",
        "last_name": "User",
    }
    with patch("app.routers.auth.httpx.AsyncClient") as mock_client:
        mock_instance = AsyncMock()
        mock_client.return_value.__aenter__.return_value = mock_instance
        
        mock_resp_token = MagicMock()
        mock_resp_token.status_code = 200
        mock_resp_token.json.return_value = {"access_token": "admin-token"}
        
        mock_resp_register = MagicMock()
        mock_resp_register.status_code = 201
        mock_resp_register.json.return_value = {"id": "new-user-id"}
        
        mock_instance.post.side_effect = [mock_resp_token, mock_resp_register]

        response = client.post("/auth/register", json=payload)
        assert response.status_code in [200, 201], response.text

def test_register_duplicate_email(client: TestClient):
    """AUTH-02: Register duplicate user (mocked conflict)"""
    payload = {
        "email": "existing@example.com",
        "username": "existing",
        "password": "StrongPassword123!",
        "first_name": "Existing",
        "last_name": "User",
    }
    with patch("app.routers.auth.httpx.AsyncClient") as mock_client:
        mock_instance = AsyncMock()
        mock_client.return_value.__aenter__.return_value = mock_instance

        mock_resp_token = MagicMock()
        mock_resp_token.status_code = 200
        mock_resp_token.json.return_value = {"access_token": "admin-token"}

        mock_resp_register = MagicMock()
        mock_resp_register.status_code = 409
        mock_resp_register.json.return_value = {"error": "Conflict"}
        
        mock_instance.post.side_effect = [mock_resp_token, mock_resp_register]

        response = client.post("/auth/register", json=payload)
        assert response.status_code == 409

def test_register_missing_field(client: TestClient):
    """AUTH-03: Register missing required field"""
    payload = {
        "username": "newuser",
    }
    response = client.post("/auth/register", json=payload)
    assert response.status_code == 422

def test_login_valid_credentials_returns_token_and_authorizes_scoped_routes(
    client: TestClient,
):
    """AUTH-09: Credentials produce an access token that carries API scopes."""
    payload = {"email": "valid@example.com", "password": "validpassword"}

    with patch("httpx.AsyncClient") as mock_http_client:
        http_instance = AsyncMock()
        mock_http_client.return_value.__aenter__.return_value = http_instance

        def response(status_code, body):
            mock_resp = MagicMock()
            mock_resp.status_code = status_code
            mock_resp.content = b"{}"
            mock_resp.json.return_value = body
            return mock_resp

        async def auth_post(url, *args, **kwargs):
            if url.endswith("/oauth2/authorize/"):
                return response(
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
                return response(
                    200,
                    {
                        "flowStatus": "SUCCESS_COMPLETED",
                        "authData": {"code": "code-123"},
                    },
                )
            if url.endswith("/oauth2/token"):
                return response(
                    200,
                    {
                        "access_token": "scoped-access-token",
                        "refresh_token": "refresh-token",
                        "token_type": "Bearer",
                        "scope": "openid profile email settings_read",
                    },
                )
            raise AssertionError(f"Unexpected auth POST URL: {url}")

        async def verify_get(url, *args, **kwargs):
            assert kwargs["headers"]["Authorization"] == "Bearer scoped-access-token"
            return response(
                200,
                {
                    "sub": "user-id-123",
                    "email": "valid@example.com",
                    "given_name": "Valid",
                    "family_name": "User",
                },
            )

        async def verify_post(url, *args, **kwargs):
            if url.endswith("/oauth2/introspect"):
                return response(
                    200,
                    {
                        "active": True,
                        "scope": "openid profile email settings_read books_read",
                        "groups": ["member"],
                    },
                )
            raise AssertionError(f"Unexpected verify POST URL: {url}")

        async def post(url, *args, **kwargs):
            if url.endswith("/oauth2/introspect"):
                return await verify_post(url, *args, **kwargs)
            return await auth_post(url, *args, **kwargs)

        http_instance.post.side_effect = post
        http_instance.get.side_effect = verify_get

        login_response = client.post("/auth/login/credentials", json=payload)
        assert login_response.status_code == 200
        login_body = login_response.json()
        access_token = login_body["access_token"]
        assert access_token == "scoped-access-token"
        assert login_body["refresh_token"] == "refresh-token"
        assert login_body["user"]["email"] == "valid@example.com"

        headers = {"Authorization": f"Bearer {access_token}"}
        identity_response = client.get("/auth/debug/identity", headers=headers)
        assert identity_response.status_code == 200
        identity_body = identity_response.json()
        assert identity_body["subject_present"] is True
        assert "settings_read" in identity_body["scopes_seen"]
        assert "books_read" in identity_body["scopes_seen"]

        settings_response = client.get("/settings/", headers=headers)
        assert settings_response.status_code == 200

def test_access_protected_route_no_token(client: TestClient):
    """AUTH-19: Missing token rejected"""
    response = client.get("/settings/")
    assert response.status_code in [401, 403]
