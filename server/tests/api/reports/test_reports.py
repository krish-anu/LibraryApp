from fastapi.testclient import TestClient


def test_reports_routes_are_not_exposed_until_reporting_module_exists(
    client: TestClient, admin_user
):
    response = client.get("/reports/circulation")

    assert response.status_code == 404
