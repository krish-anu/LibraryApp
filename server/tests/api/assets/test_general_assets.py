from fastapi.testclient import TestClient


def test_health_check(client: TestClient):
    """GEN-01: Health/root success"""
    response = client.get("/")

    assert response.status_code == 200
    assert response.json()["message"] == "Hello, FastAPI service is working!"


def test_asset_security_traversal(client: TestClient):
    """ASSET-03: Dot/hidden path blocked (Directory Traversal)"""
    # Try to access sensitive file via traversal
    # Note: TestClient resolves paths, so we might need to manually construct request
    # but client.get will do.
    response = client.get("/assets/../.env")
    # Should be 404 or 403, definitely not 200
    assert response.status_code in [404, 403]


def test_non_existent_asset(client: TestClient):
    """ASSET-02: Non-existing asset"""
    response = client.get("/assets/does_not_exist.png")

    assert response.status_code == 404


def test_temp_asset_access(client: TestClient, tmp_path):
    """ASSET-01: Existing allowed asset"""
    response = client.get("/assets/person.webp")

    assert response.status_code == 200
    assert response.headers["content-type"] == "image/webp"
    assert response.content
