import pytest
from fastapi.testclient import TestClient

from app.models.users import User as UserModel

# Assuming we have a fixture to create a user in DB,
# or we mock the auth dependency to return a specific user ID.

VALID_PNG_BYTES = (
    b"\x89PNG\r\n\x1a\n"
    b"\x00\x00\x00\rIHDR"
    b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00"
    b"\x90wS\xde"
    b"\x00\x00\x00\x00IEND\xaeB`\x82"
)


def _create_authenticated_test_user(db_session):
    user = UserModel(
        id="test-user-id",
        member_id="MTEST001",
        name="Test User",
        email="test@example.com",
    )
    db_session.add(user)
    db_session.commit()
    return user


def test_get_own_profile(client: TestClient, override_auth_dependency, db_session):
    """USER-01: Get own profile"""
    override_auth_dependency()
    _create_authenticated_test_user(db_session)

    response = client.get("/users/test-user-id")

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "test-user-id"
    assert data["name"] == "Test User"
    assert data["email"] == "test@example.com"


def test_update_profile_valid(client: TestClient, override_auth_dependency, db_session):
    """USER-02: Update profile valid"""
    override_auth_dependency()
    _create_authenticated_test_user(db_session)
    payload = {"name": "Updated Name"}

    response = client.put("/users/test-user-id", json=payload)

    assert response.status_code == 200
    assert response.json()["name"] == "Updated Name"


def test_update_restricted_fields(client: TestClient, override_auth_dependency, db_session):
    """USER-04: Update restricted fields (e.g. role)"""
    override_auth_dependency()
    _create_authenticated_test_user(db_session)
    # Try to become admin
    payload = {"role": "admin"}

    response = client.put("/users/test-user-id", json=payload)

    assert response.status_code == 200
    assert "role" not in response.json()


def test_admin_list_users(client: TestClient):
    """USER-06: Admin list users"""
    # Need to simulate admin role
    # This likely requires a different override or mocking roles
    pass


def test_upload_and_fetch_profile_image_blob(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    user = _create_authenticated_test_user(db_session)

    upload_res = client.put(
        "/users/test-user-id/profile-image",
        content=VALID_PNG_BYTES,
        headers={"Content-Type": "image/png"},
    )

    assert upload_res.status_code == 200
    assert upload_res.json()["profile_image"] == "/users/test-user-id/profile-image"

    db_session.refresh(user)
    assert bytes(user.profile_image_blob) == VALID_PNG_BYTES
    assert user.profile_image_mime_type == "image/png"

    image_res = client.get("/users/test-user-id/profile-image")
    assert image_res.status_code == 200
    assert image_res.headers["content-type"] == "image/png"
    assert image_res.content == VALID_PNG_BYTES
