from unittest.mock import AsyncMock, MagicMock, patch

from fastapi.testclient import TestClient


def test_logout_revokes_access_token(client: TestClient):
    with patch("app.routers.auth.ASGARDEO_PUBLIC_CLIENT_ID", "test-public"), patch(
        "app.routers.auth.ASGARDEO_BASE_URL", "https://api.asgardeo.io/t/test"
    ), patch("httpx.AsyncClient") as mock_http_client:
        http_instance = AsyncMock()
        mock_http_client.return_value.__aenter__.return_value = http_instance

        revoke_response = MagicMock()
        revoke_response.status_code = 200
        http_instance.post.return_value = revoke_response

        response = client.post("/auth/logout", json={"access_token": "access-token"})

    assert response.status_code == 200
    assert response.json() == {"success": True}
    http_instance.post.assert_called_once()
    url = http_instance.post.call_args.args[0]
    data = http_instance.post.call_args.kwargs["data"]
    assert url.endswith("/oauth2/revoke")
    assert data == {"token": "access-token", "client_id": "test-public"}
