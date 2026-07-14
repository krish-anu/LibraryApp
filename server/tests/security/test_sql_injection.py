from fastapi.testclient import TestClient

from app.models.users import User


def test_search_inputs_do_not_break_queries_or_return_unrelated_rows(
    client: TestClient, admin_user, db_session
):
    db_session.add_all(
        [
            User(id="safe-user", member_id="MSAFE", name="Safe User", email="safe@example.com"),
            User(id="target-user", member_id="MTARGET", name="Target User", email="target@example.com"),
        ]
    )
    db_session.commit()

    response = client.get("/users/", params={"search": "' OR '1'='1"})

    assert response.status_code == 200
    assert response.json()["totalCount"] == 0


def test_search_matches_only_expected_user(client: TestClient, admin_user, db_session):
    db_session.add_all(
        [
            User(id="safe-user", member_id="MSAFE", name="Safe User", email="safe@example.com"),
            User(id="target-user", member_id="MTARGET", name="Target User", email="target@example.com"),
        ]
    )
    db_session.commit()

    response = client.get("/users/", params={"search": "Target"})

    assert response.status_code == 200
    assert response.json()["totalCount"] == 1
    assert response.json()["data"][0]["id"] == "target-user"
