import os
import re

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, make_url
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import sessionmaker


DEFAULT_TEST_DATABASE_URL = (
    "postgresql+psycopg2://postgres:postgres@localhost:15432/libraryapp_test"
)


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


TEST_DATABASE_URL = _resolve_test_database_url()
_ensure_database_exists(TEST_DATABASE_URL)
os.environ["DATABASE_URL"] = TEST_DATABASE_URL.render_as_string(hide_password=False)

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
