import os
import re
from pathlib import Path

import pytest
from dotenv import dotenv_values
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, make_url
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import sessionmaker


DEFAULT_TEST_DATABASE_URL = (
    "postgresql+psycopg2://postgres:postgres@localhost:15432/libraryapp_test"
)
SERVER_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = SERVER_ROOT.parent
AUTH_ENV_KEYS = {
    "ADMIN_GROUPS",
    "ADMIN_EMAILS",
    "ADMIN_SUBJECTS",
    "ASGARDEO_BASE_URL",
    "ASGARDEO_CLIENT_ID",
    "ASGARDEO_CLIENT_SECRET",
    "ASGARDEO_INTROSPECTION_CLIENT_ID",
    "ASGARDEO_INTROSPECTION_CLIENT_SECRET",
    "ASGARDEO_M2M_CLIENT_ID",
    "ASGARDEO_M2M_CLIENT_SECRET",
    "ASGARDEO_PUBLIC_CLIENT_ID",
    "ASGARDEO_PUBLIC_CLIENT_SECRET",
    "ASGARDEO_REDIRECT_URL",
    "ASGARDEO_SCOPE",
    "ASGARDEO_TOKEN_ENDPOINT",
    "ASGARDEO_USERINFO_ENDPOINT",
    "E2E_ADMIN_EMAIL",
    "E2E_ADMIN_PASSWORD",
    "E2E_ADMIN_SUBJECT",
    "E2E_MEMBER_EMAIL",
    "E2E_MEMBER_PASSWORD",
    "NEXT_PUBLIC_ASGARDEO_BASE_URL",
    "NEXT_PUBLIC_ASGARDEO_CLIENT_ID",
    "NEXT_PUBLIC_ASGARDEO_SCOPES",
}


def _load_auth_env_files() -> None:
    for env_file in (
        SERVER_ROOT / ".env.local",
        PROJECT_ROOT / "admin" / ".env.local",
        PROJECT_ROOT / "admin" / ".env.e2e.local",
        SERVER_ROOT / ".env.test",
    ):
        if not env_file.exists():
            continue
        for key, value in dotenv_values(env_file).items():
            if key in AUTH_ENV_KEYS and value is not None:
                os.environ.setdefault(key, value)

    def copy_if_present(target: str, *sources: str) -> None:
        if os.getenv(target):
            return
        for source in sources:
            value = os.getenv(source)
            if value:
                os.environ[target] = value
                return

    copy_if_present("ASGARDEO_BASE_URL", "NEXT_PUBLIC_ASGARDEO_BASE_URL")
    copy_if_present(
        "ASGARDEO_PUBLIC_CLIENT_ID",
        "ASGARDEO_CLIENT_ID",
        "NEXT_PUBLIC_ASGARDEO_CLIENT_ID",
    )
    copy_if_present(
        "ASGARDEO_INTROSPECTION_CLIENT_ID",
        "ASGARDEO_CLIENT_ID",
        "ASGARDEO_PUBLIC_CLIENT_ID",
    )
    copy_if_present(
        "ASGARDEO_INTROSPECTION_CLIENT_SECRET",
        "ASGARDEO_CLIENT_SECRET",
        "ASGARDEO_PUBLIC_CLIENT_SECRET",
    )
    copy_if_present("ASGARDEO_SCOPE", "NEXT_PUBLIC_ASGARDEO_SCOPES")
    copy_if_present("ADMIN_EMAILS", "E2E_ADMIN_EMAIL")
    copy_if_present("ADMIN_SUBJECTS", "E2E_ADMIN_SUBJECT")

    token_endpoint = os.getenv("ASGARDEO_TOKEN_ENDPOINT", "").rstrip("/")
    if token_endpoint.endswith("/oauth2/token") and not os.getenv("ASGARDEO_BASE_URL"):
        os.environ["ASGARDEO_BASE_URL"] = token_endpoint[: -len("/oauth2/token")]


def _resolve_test_database_url() -> URL:
    raw_url = os.getenv("TEST_DATABASE_URL") or os.getenv("DATABASE_URL")
    raw_url = raw_url or DEFAULT_TEST_DATABASE_URL
    url = make_url(raw_url)

    if url.get_backend_name() != "postgresql":
        raise RuntimeError(
            "Server tests must use PostgreSQL. Set TEST_DATABASE_URL to a "
            "postgresql+psycopg2://... URL for a disposable test database."
        )

    database = url.database or ""
    if "test" not in database.lower():
        raise RuntimeError(
            "Refusing to run tests against a non-test PostgreSQL database. "
            "Use a database name containing 'test', for example libraryapp_test."
        )

    return url


def _ensure_database_exists(url: URL) -> None:
    database = url.database or ""
    if not re.fullmatch(r"[A-Za-z0-9_-]+", database):
        raise RuntimeError(
            "Test database name may only contain letters, numbers, underscores, and hyphens."
        )

    admin_url = url.set(database="postgres")
    admin_engine = create_engine(admin_url, isolation_level="AUTOCOMMIT")
    try:
        try:
            with admin_engine.connect() as connection:
                exists = connection.execute(
                    text("SELECT 1 FROM pg_database WHERE datname = :database"),
                    {"database": database},
                ).scalar()
                if not exists:
                    connection.execute(text(f'CREATE DATABASE "{database}"'))
        except OperationalError as exc:
            raise RuntimeError(
                "Could not connect to PostgreSQL for tests. Start Postgres or set "
                "TEST_DATABASE_URL to a reachable disposable PostgreSQL database. "
                f"Current test URL: {url.render_as_string(hide_password=True)}"
            ) from exc
    finally:
        admin_engine.dispose()


_load_auth_env_files()

TEST_DATABASE_URL = _resolve_test_database_url()
_ensure_database_exists(TEST_DATABASE_URL)
os.environ["DATABASE_URL"] = TEST_DATABASE_URL.render_as_string(hide_password=False)
os.environ.setdefault("ASGARDEO_BASE_URL", "https://api.asgardeo.io/t/test")

from app.api.dependencies import get_db, verify_access_token
from app.main import app as main_app
from app.models.base import Base


SQLALCHEMY_DATABASE_URL = TEST_DATABASE_URL.render_as_string(hide_password=False)
ALL_TEST_SCOPES = (
    "openid profile email "
    "dashboard_read "
    "books_read books_manage "
    "content_read content_manage "
    "categories_read categories_manage "
    "loans_read loans_manage "
    "reservations_read reservations_manage "
    "favorites_read favorites_manage "
    "users_read users_manage "
    "fines_read fines_manage "
    "notifications_read notifications_manage "
    "settings_read settings_manage"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture
def app():
    return main_app


@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    main_app.dependency_overrides[get_db] = override_get_db
    from app.services.sheet_sync.scheduler import sheet_sync_scheduler

    original_start = sheet_sync_scheduler.start
    original_stop = sheet_sync_scheduler.stop

    async def noop_scheduler_start():
        return None

    async def noop_scheduler_stop():
        return None

    sheet_sync_scheduler.start = noop_scheduler_start
    sheet_sync_scheduler.stop = noop_scheduler_stop

    with TestClient(main_app) as client_instance:
        yield client_instance

    sheet_sync_scheduler.start = original_start
    sheet_sync_scheduler.stop = original_stop
    main_app.dependency_overrides.clear()


@pytest.fixture
def auth_headers():
    return {"Authorization": "Bearer test-token"}


@pytest.fixture
def override_auth_dependency(client):
    async def mock_verify_token(authorization: str = None):  # type: ignore
        return {
            "sub": "test-user-id",
            "username": "testuser",
            "email": "test@example.com",
            "scope": ALL_TEST_SCOPES,
        }

    main_app.dependency_overrides[verify_access_token] = mock_verify_token
    return mock_verify_token


@pytest.fixture
def admin_user(app):
    async def mock_admin_token(authorization: str = None):  # type: ignore
        return {
            "sub": "admin-user-id",
            "username": "admin",
            "email": "admin@example.com",
            "groups": ["admin"],
            "scope": ALL_TEST_SCOPES,
        }

    app.dependency_overrides[verify_access_token] = mock_admin_token
    yield mock_admin_token
    app.dependency_overrides.pop(verify_access_token, None)


@pytest.fixture
def user_headers():
    return {"Authorization": "Bearer fake-token"}
