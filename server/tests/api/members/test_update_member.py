from fastapi.testclient import TestClient

from app.models.users import User


def test_member_can_update_own_contact_details(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add(
        User(id="test-user-id", member_id="MTEST", name="Test Member", email="member@example.com")
    )
    db_session.commit()

    response = client.put(
        "/users/test-user-id",
        json={"phone": "0777654321", "address": "Updated Street"},
    )

    assert response.status_code == 200
    assert response.json()["phone"] == "0777654321"
    assert response.json()["address"] == "Updated Street"


def test_member_cannot_update_another_member(
    client: TestClient, override_auth_dependency, db_session
):
    override_auth_dependency()
    db_session.add(
        User(id="other-user-id", member_id="MOTHER", name="Other", email="other@example.com")
    )
    db_session.commit()

    response = client.put("/users/other-user-id", json={"address": "Nope"})

    assert response.status_code == 403
