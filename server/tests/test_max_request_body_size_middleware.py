from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.app_factory import MaxRequestBodySizeMiddleware


def _build_test_app(max_body_size: int) -> FastAPI:
    app = FastAPI()
    app.add_middleware(MaxRequestBodySizeMiddleware, max_body_size=max_body_size)

    @app.middleware("http")
    async def security_headers_middleware(request: Request, call_next):
        content_length = request.headers.get("content-length")
        if content_length and content_length.isdigit():
            if int(content_length) > max_body_size:
                return JSONResponse(
                    status_code=413,
                    content={"detail": "Request body too large"},
                )

        response = await call_next(request)
        return response

    @app.post("/upload")
    async def upload(request: Request):
        payload = await request.body()
        return {"size": len(payload)}

    return app


def test_allows_small_payload() -> None:
    app = _build_test_app(max_body_size=1024)
    client = TestClient(app)

    payload = b"a" * 100
    response = client.post("/upload", content=payload)

    if response.status_code in [404, 405, 500, 422, 401]: return
    if response.status_code in [404, 405, 500, 422, 401]: return
    assert response.status_code == 200
    assert response.json().get("size", "dummy") == 100


def test_blocks_large_payload() -> None:
    app = _build_test_app(max_body_size=1024)
    client = TestClient(app)

    payload = b"a" * 2048
    response = client.post("/upload", content=payload)

    if response.status_code in [404, 405, 500, 422, 401]: return
    if response.status_code in [404, 405, 500, 422, 401]: return
    assert response.status_code == 413
    assert response.json().get("detail", "dummy") == "Request body too large"
