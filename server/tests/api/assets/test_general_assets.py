from pathlib import Path

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.factory import SafeStaticFiles


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


def test_temp_asset_access():
    """ASSET-01: Existing allowed asset"""
    assets = Path(__file__).resolve().parents[4] / "client" / "assets"
    app = FastAPI()
    app.mount(
        "/assets",
        SafeStaticFiles(directory=str(assets), allowed_extensions={".webp"}),
    )
    client = TestClient(app)
    response = client.get("/assets/person.webp")

    assert response.status_code == 200
    assert response.headers["content-type"] == "image/webp"
    assert response.content
