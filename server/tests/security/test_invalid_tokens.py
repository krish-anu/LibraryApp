from fastapi.testclient import TestClient


def test_missing_token_returns_unauthorized(client: TestClient):
    response = client.get("/books/")

    assert response.status_code == 401
    assert response.json()["detail"] == "Missing Authorization header"


def test_malformed_authorization_header_returns_unauthorized(client: TestClient):
    response = client.get("/books/", headers={"Authorization": "not-a-bearer-token"})

    assert response.status_code == 401
    assert "Expected: Bearer <token>" in response.json()["detail"]
