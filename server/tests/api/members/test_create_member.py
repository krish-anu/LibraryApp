from fastapi.testclient import TestClient


def test_admin_can_create_member_with_unique_email(client: TestClient, admin_user):
    response = client.post(
        "/users/",
        json={
            "name": "New Member",
            "email": "new.member@example.com",
            "phone": "0771234567",
            "address": "Library Street",
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["id"]
    assert body["member_id"].startswith("M")
    assert body["email"] == "new.member@example.com"


def test_create_member_rejects_duplicate_email(client: TestClient, admin_user):
    payload = {"name": "Member", "email": "duplicate@example.com"}
    assert client.post("/users/", json=payload).status_code == 201

    response = client.post("/users/", json={**payload, "name": "Other Member"})

    assert response.status_code == 409
