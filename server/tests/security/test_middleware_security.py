from fastapi.testclient import TestClient


def test_security_headers_present(client: TestClient):
    """SEC-15 to SEC-18: Verify security headers"""
    response = client.get("/")
    headers = response.headers

    assert headers["x-content-type-options"] == "nosniff"
    assert headers["x-frame-options"] == "DENY"
    assert headers["referrer-policy"] == "no-referrer"
    assert "camera=()" in headers["permissions-policy"]


def test_cors_preflight(client: TestClient):
    """SEC-04: OPTIONS preflight behavior"""
    headers = {
        "Origin": "http://localhost:3000",
        "Access-Control-Request-Method": "GET",
    }
    response = client.options("/", headers=headers)

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:3000"


# Note: Body size tests are in test_max_request_body_size_middleware.py
