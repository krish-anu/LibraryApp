from datetime import date

from fastapi.testclient import TestClient

from app.models.users import User


def test_fine_summary_counts_only_unpaid_amounts(
    client: TestClient, admin_user, db_session
):
    db_session.add(
        User(id="summary-member", member_id="M_SUM", name="Summary Member", email="sum@example.com")
    )
    db_session.commit()

    first = client.post(
        "/fines/",
        json={
            "member_id": "summary-member",
            "fine_amount": 3,
            "fine_date": date.today().isoformat(),
            "reason": "Overdue",
        },
    )
    second = client.post(
        "/fines/",
        json={
            "member_id": "summary-member",
            "fine_amount": 7,
            "fine_date": date.today().isoformat(),
            "reason": "Damage",
        },
    )
    assert first.status_code == 201
    assert second.status_code == 201
    client.put(f"/fines/{first.json()['data']['id']}", json={"status": "paid"})

    response = client.get("/fines/member/summary-member/summary")

    assert response.status_code == 200
    assert response.json()["total_due"] == 7.0
    assert response.json()["unpaid_count"] == 1


def test_fine_creation_rejects_non_positive_amount(client: TestClient, admin_user):
    response = client.post(
        "/fines/",
        json={
            "member_id": "missing-member",
            "fine_amount": 0,
            "fine_date": date.today().isoformat(),
            "reason": "Invalid",
        },
    )

    assert response.status_code == 422
