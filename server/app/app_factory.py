import os
from pathlib import Path
from typing import cast

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
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


def create_app() -> FastAPI:
    app = FastAPI(title="Library App API", lifespan=lifespan)

    limiter = Limiter(key_func=get_remote_address, default_limits=["60/minute"])
    app.state.limiter = limiter
    app.add_exception_handler(
        RateLimitExceeded,
        cast(ExceptionHandler, _rate_limit_exceeded_handler),
    )

    allowed_origins = os.getenv(
        "ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000"
    ).split(",")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[origin.strip() for origin in allowed_origins],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
        allow_headers=["*"],
    )

    # Serve Flutter client assets (book covers etc.) at /assets when available.
    server_root = Path(__file__).resolve().parents[1]
    repo_root = server_root.parent
    project_root = repo_root if (repo_root / "client").exists() else server_root
    client_assets = project_root / "client" / "assets"
    if client_assets.exists():
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
