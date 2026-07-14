from fastapi.testclient import TestClient

from app.models.users import User


def test_member_can_get_own_profile(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add(
        User(
            id="test-user-id",
            member_id="MTEST",
            name="Test Member",
            email="member@example.com",
        )
    )
    db_session.commit()

    response = client.get("/users/test-user-id")

    assert response.status_code == 200
    assert response.json()["email"] == "member@example.com"


def test_member_stats_default_to_zero(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add(
        User(id="test-user-id", member_id="MTEST", name="Test Member", email="member@example.com")
    )
    db_session.commit()

    response = client.get("/users/test-user-id/stats")

    assert response.status_code == 200
    assert response.json() == {
        "total_borrows": 0,
        "books_read": 0,
        "total_fines": 0.0,
        "active_loans": 0,
        "active_reservations": 0,
    }
