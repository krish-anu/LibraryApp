import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.api.dependencies import get_db, verify_access_token
from app.main import app as main_app
from app.models.base import Base


SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
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

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)


@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


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
