from fastapi.testclient import TestClient


def test_refresh_token_endpoint_is_not_exposed_until_implemented(client: TestClient):
    response = client.post("/auth/refresh", json={"refresh_token": "refresh-token"})

    assert response.status_code == 404
