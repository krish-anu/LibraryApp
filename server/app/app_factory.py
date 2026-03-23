import os
from pathlib import Path
from typing import cast

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from starlette.types import ExceptionHandler

from .routers import (
    auth,
    books,
    category,
    favorites,
    general,
    loans,
    reservations,
    settings,
    users,
)
from .startup import lifespan


def _env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def _parse_allowed_origins() -> list[str]:
    raw = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000")
    origins = [origin.strip() for origin in raw.split(",") if origin.strip()]
    allow_credentials = _env_bool("CORS_ALLOW_CREDENTIALS", True)

    if allow_credentials and "*" in origins:
        raise ValueError(
            "ALLOWED_ORIGINS cannot contain '*' when CORS_ALLOW_CREDENTIALS is true"
        )

    return origins


def _client_identifier(request: Request) -> str:
    trust_proxy_headers = _env_bool("TRUST_PROXY_HEADERS", False)

    if trust_proxy_headers:
        x_forwarded_for = request.headers.get("x-forwarded-for")
        if x_forwarded_for:
            first = x_forwarded_for.split(",")[0].strip()
            if first:
                return first

        x_real_ip = request.headers.get("x-real-ip")
        if x_real_ip:
            real = x_real_ip.strip()
            if real:
                return real

    if request.client and request.client.host:
        return request.client.host

    return "unknown"


def create_app() -> FastAPI:
    app = FastAPI(title="Library App API", lifespan=lifespan)

    default_limit = os.getenv("DEFAULT_RATE_LIMIT", "60/minute")
    limiter = Limiter(key_func=_client_identifier, default_limits=[default_limit])
    app.state.limiter = limiter
    app.add_exception_handler(
        RateLimitExceeded,
        cast(ExceptionHandler, _rate_limit_exceeded_handler),
    )

    allowed_origins = _parse_allowed_origins()
    allow_credentials = _env_bool("CORS_ALLOW_CREDENTIALS", True)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=allow_credentials,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"],
        allow_headers=["*"],
    )

    max_request_size_bytes = int(os.getenv("MAX_REQUEST_SIZE_BYTES", "10485760"))

    @app.middleware("http")
    async def security_headers_middleware(
        request: Request, call_next
    ):
        content_length = request.headers.get("content-length")
        if content_length and content_length.isdigit():
            if int(content_length) > max_request_size_bytes:
                return JSONResponse(
                    status_code=413,
                    content={"detail": "Request body too large"},
                )

        response = await call_next(request)
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "no-referrer")
        response.headers.setdefault(
            "Permissions-Policy", "camera=(), microphone=(), geolocation=()"
        )
        return response

    # Serve Flutter client assets (book covers etc.) at /assets when available.
    server_root = Path(__file__).resolve().parents[1]
    repo_root = server_root.parent
    project_root = repo_root if (repo_root / "client").exists() else server_root
    client_assets = project_root / "client" / "assets"
    environment = os.getenv("ENVIRONMENT", "development").strip().lower()
    default_serve_assets = environment != "production"
    serve_local_assets = _env_bool("SERVE_LOCAL_ASSETS", default_serve_assets)
    if serve_local_assets and client_assets.exists():
        app.mount("/assets", StaticFiles(directory=str(client_assets)), name="assets")

    app.include_router(general.router)
    app.include_router(auth.router)
    app.include_router(books.router)
    app.include_router(loans.router)
    app.include_router(category.router)
    app.include_router(favorites.router)
    app.include_router(users.router)
    app.include_router(reservations.router)
    app.include_router(settings.router)

    return app
