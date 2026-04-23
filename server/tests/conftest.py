import pytest
from fastapi.testclient import TestClient

from app.dependencies import get_db, get_store, verify_access_token
from app.firestore_store import InMemoryLibraryStore
from app.main import app as main_app


@pytest.fixture
def app():
    return main_app


@pytest.fixture(scope="function")
def db_session():
    return InMemoryLibraryStore()


@pytest.fixture(scope="function")
def client(db_session):
    def override_get_store():
        return db_session

    def override_get_db():
        yield db_session

    main_app.dependency_overrides[get_store] = override_get_store
    main_app.dependency_overrides[get_db] = override_get_db

    with TestClient(main_app) as c:
        yield c

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
            "scope": "openid profile email",
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
        }

    app.dependency_overrides[verify_access_token] = mock_admin_token
    yield mock_admin_token
    app.dependency_overrides.pop(verify_access_token, None)


@pytest.fixture
def user_headers():
    return {"Authorization": "Bearer fake-token"}
