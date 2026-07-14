from fastapi.testclient import TestClient

from app.models.users import User


def test_member_cannot_access_another_member_resource(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add(
        User(id="member-b", member_id="MB", name="Member B", email="b@example.com")
    )
    db_session.commit()

    response = client.get("/users/member-b")

    assert response.status_code == 403
    assert response.json()["detail"] == "You are not allowed to access this resource"
