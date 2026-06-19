import os
from pathlib import Path
from typing import Sequence, cast

from fastapi import APIRouter, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from starlette.types import ExceptionHandler

from .security import (
    create_limiter,
    env_bool,
    env_int,
    parse_allowed_origins,
)
from .routers import (
    auth,
    books,
    category,
    favorites,
    general,
    loans,
    notifications,
    reservations,
    settings,
    users,
)
from .startup import lifespan


class MaxBodySizeExceeded(Exception):
    pass


class MaxRequestBodySizeMiddleware:
    def __init__(self, app, max_body_size: int):
        self.app = app
        self.max_body_size = max_body_size

    async def __call__(self, scope, receive, send):
        if scope.get("type") != "http":
            await self.app(scope, receive, send)
            return

        received = 0

        async def limited_receive():
            nonlocal received
            message = await receive()

            if message.get("type") == "http.request":
                chunk = message.get("body", b"")
                received += len(chunk)
                if received > self.max_body_size:
                    raise MaxBodySizeExceeded()

            return message

        try:
            await self.app(scope, limited_receive, send)
        except MaxBodySizeExceeded:
            response = JSONResponse(
                status_code=413,
                content={"detail": "Request body too large"},
            )
            await response(scope, receive, send)


class SafeStaticFiles(StaticFiles):
    def __init__(self, *args, allowed_extensions: set[str] | None = None, **kwargs):
        super().__init__(*args, **kwargs)
        self.allowed_extensions = allowed_extensions

    async def get_response(self, path: str, scope):
        normalized = Path(path)
        if any(part.startswith(".") for part in normalized.parts):
            return JSONResponse(status_code=404, content={"detail": "Not Found"})

        if self.allowed_extensions is not None:
            suffix = normalized.suffix.lower()
            if suffix not in self.allowed_extensions:
                return JSONResponse(status_code=404, content={"detail": "Not Found"})

        return await super().get_response(path, scope)


def _parse_asset_extensions(default_serve_assets: bool) -> set[str] | None:
    enforce_allowlist = env_bool("ASSET_EXTENSION_ALLOWLIST", not default_serve_assets)
    if not enforce_allowlist:
        return None

    raw = os.getenv("ALLOWED_ASSET_EXTENSIONS", ".jpg,.jpeg,.png,.webp,.gif,.svg")
    exts = {part.strip().lower() for part in raw.split(",") if part.strip()}
    normalized = {ext if ext.startswith(".") else f".{ext}" for ext in exts}
    return normalized


DEFAULT_ROUTERS: tuple[APIRouter, ...] = (
    general.router,
    auth.router,
    books.router,
    loans.router,
    notifications.router,
    category.router,
    favorites.router,
    users.router,
    reservations.router,
    settings.router,
)


def create_app(
    title: str = "Library App API",
    routers: Sequence[APIRouter] | None = None,
    serve_assets: bool | None = None,
) -> FastAPI:
    app = FastAPI(title=title, lifespan=lifespan)

    default_limit = os.getenv("DEFAULT_RATE_LIMIT", "60/minute")
    limiter = create_limiter(default_limits=[default_limit])
    app.state.limiter = limiter
    app.add_exception_handler(
        RateLimitExceeded,
        cast(ExceptionHandler, _rate_limit_exceeded_handler),
    )

    allowed_origins = parse_allowed_origins()
    allow_credentials = env_bool("CORS_ALLOW_CREDENTIALS", True)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=allow_credentials,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"],
        allow_headers=["*"],
    )

    max_request_size_bytes = env_int("MAX_REQUEST_SIZE_BYTES", 10485760, minimum=1024)
    app.add_middleware(
        MaxRequestBodySizeMiddleware, max_body_size=max_request_size_bytes
    )

    @app.middleware("http")
    async def security_headers_middleware(request: Request, call_next):
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
        if environment == "production":
            response.headers.setdefault(
                "Strict-Transport-Security",
                "max-age=31536000; includeSubDomains",
            )
        if request.url.path.startswith("/auth/"):
            response.headers.setdefault("Cache-Control", "no-store")
        return response

    # Serve Flutter client assets (book covers etc.) at /assets when available.
    server_root = Path(__file__).resolve().parents[1]
    repo_root = server_root.parent
    project_root = repo_root if (repo_root / "client").exists() else server_root
    client_assets = project_root / "client" / "assets"
    environment = os.getenv("ENVIRONMENT", "development").strip().lower()
    default_serve_assets = environment != "production"
    serve_local_assets = (
        env_bool("SERVE_LOCAL_ASSETS", default_serve_assets)
        if serve_assets is None
        else serve_assets
    )
    allowed_asset_extensions = _parse_asset_extensions(default_serve_assets)
    if serve_local_assets and client_assets.exists():
        app.mount(
            "/assets",
            SafeStaticFiles(
                directory=str(client_assets),
                allowed_extensions=allowed_asset_extensions,
            ),
            name="assets",
        )

    selected_routers = tuple(routers) if routers is not None else DEFAULT_ROUTERS
    for router in selected_routers:
        app.include_router(router)

    return app
