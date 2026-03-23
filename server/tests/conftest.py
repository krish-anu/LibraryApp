import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app as main_app
from app.dependencies import get_db, verify_access_token
from app.models.base import Base

# Use in-memory SQLite database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)


# Enable foreign key enforcement for SQLite
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
    """Create a new database session for a test."""
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db_session):
    """Create a TestClient with overridden dependencies."""

    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    main_app.dependency_overrides[get_db] = override_get_db

    # By default, we might want to override auth to allow requests,
    # or tests can override it specifically.
    # For now, we'll leave auth active so we can test it,
    # but provide a helper fixture to bypass it.

    with TestClient(main_app) as c:
        yield c

    main_app.dependency_overrides.clear()


@pytest.fixture
def auth_headers():
    """Return headers for an authenticated user."""
    # This token is a placeholder. Tests that mock verify_access_token
    # will determine what user this token resolves to.
    return {"Authorization": "Bearer test-token"}


@pytest.fixture
def override_auth_dependency(client):
    """Fixture to override authentication to return a default user."""

    async def mock_verify_token(authorization: str = None):  # type: ignore
        return {
            "sub": "test-user-id",
            "username": "testuser",
            "email": "test@example.com",
            "scope": "openid profile email",
        }

    main_app.dependency_overrides[verify_access_token] = mock_verify_token
    return mock_verify_token


@pytest.fixture
def admin_user(app):
    from app.dependencies import verify_access_token

    async def mock_admin_token(authorization: str = None):  # type: ignore
        return {
            "sub": "admin-user-id",
            "username": "admin",
            "email": "admin@example.com",
            "groups": ["admin"],
        }

    app.dependency_overrides[verify_access_token] = mock_admin_token
    yield mock_admin_token
    app.dependency_overrides.pop(verify_access_token, None)


@pytest.fixture
def user_headers():
    return {"Authorization": "Bearer fake-token"}
