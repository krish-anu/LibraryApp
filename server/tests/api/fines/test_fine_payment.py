from datetime import date

from fastapi.testclient import TestClient

from app.models.users import User


def test_partial_and_full_payment_update_remaining_due(
    client: TestClient, admin_user, db_session
):
    db_session.add(
        User(id="fine-member", member_id="M_FINE", name="Fine Member", email="fine@example.com")
    )
    db_session.commit()

    created = client.post(
        "/fines/",
        json={
            "member_id": "fine-member",
            "fine_amount": 10,
            "fine_date": date.today().isoformat(),
            "reason": "Overdue",
        },
    )
    assert created.status_code == 201
    fine_id = created.json()["data"]["id"]

    partial = client.put(
        f"/fines/{fine_id}",
        json={"payment_amount": 4, "payment_method": "physical"},
    )
    assert partial.status_code == 200
    assert partial.json()["payment"] == {"appliedAmount": 4.0, "remainingAmount": 6.0}
    assert partial.json()["data"]["status"] == "unpaid"

    final = client.put(
        f"/fines/{fine_id}",
        json={"payment_amount": 6, "payment_method": "physical"},
    )
    assert final.status_code == 200
    assert final.json()["payment"]["remainingAmount"] == 0
    assert final.json()["data"]["status"] == "paid"


def test_payment_cannot_exceed_current_due(client: TestClient, admin_user, db_session):
    db_session.add(
        User(id="fine-member", member_id="M_FINE", name="Fine Member", email="fine@example.com")
    )
    db_session.commit()
    created = client.post(
        "/fines/",
        json={
            "member_id": "fine-member",
            "fine_amount": 5,
            "fine_date": date.today().isoformat(),
            "reason": "Overdue",
        },
    )
    fine_id = created.json()["data"]["id"]

    response = client.put(f"/fines/{fine_id}", json={"payment_amount": 6})

    assert response.status_code == 400
    assert "exceeds" in response.json()["detail"]
