from fastapi.testclient import TestClient





def test_get_settings(client: TestClient, admin_user):
    """SET-01: Get settings"""
    response = client.get("/settings/")

    assert response.status_code == 200
    assert response.json()["loan_period_days"] == 14


def test_update_settings_valid(client: TestClient, admin_user):
    """SET-02: Update settings valid"""
    payload = {"loan_period_days": 14, "max_books_per_user": 5}
    response = client.patch("/settings/", json=payload)
    assert response.status_code == 200
    assert response.json()["loan_period_days"] == 14
    assert response.json()["max_books_per_user"] == 5

    # Verify
    get_res = client.get("/settings/")
    assert get_res.status_code == 200
    assert get_res.json()["loan_period_days"] == 14
    assert get_res.json()["max_books_per_user"] == 5


def test_update_settings_invalid(client: TestClient, admin_user):
    """SET-03: Update settings invalid"""
    payload = {"loan_period_days": -1}  # Invalid negative
    response = client.patch("/settings/", json=payload)
    assert response.status_code == 422
