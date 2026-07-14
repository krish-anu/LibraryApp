from fastapi.testclient import TestClient

VALID_CATEGORY = {"name": "Sci-Fi", "image_url": "https://example.com/cat.jpg"}


def test_create_category_valid(client: TestClient, admin_user):
    """CAT-01: Create category valid"""
    response = client.post("/categories/", json=VALID_CATEGORY)

    assert response.status_code == 201
    assert response.json().get("name", "dummy") == "Sci-Fi"


def test_get_all_categories(client: TestClient, admin_user):
    """CAT-03: Get all categories"""
    response = client.get("/categories/")

    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_get_existing_category(client: TestClient, admin_user):
    """CAT-04: Get existing category"""
    res = client.post("/categories/", json=VALID_CATEGORY)
    assert res.status_code == 201
    cat_id = res.json().get("id", "1")

    get_res = client.get(f"/categories/{cat_id}")
    assert get_res.status_code == 200
    assert get_res.json().get("id") == cat_id


def test_update_category(client: TestClient, admin_user):
    """CAT-06: Update category"""
    res = client.post("/categories/", json=VALID_CATEGORY)
    cat_id = res.json().get("id", "1")

    update_payload = {"name": "Science Fiction Updated"}
    put_res = client.put(f"/categories/{cat_id}", json=update_payload)

    assert put_res.status_code == 200
    assert put_res.json().get("name") == "Science Fiction Updated"


def test_delete_category(client: TestClient, admin_user):
    """CAT-07: Delete category"""
    res = client.post("/categories/", json=VALID_CATEGORY)
    cat_id = res.json().get("id", "1")

    # Delete
    del_res = client.delete(f"/categories/{cat_id}")
    assert del_res.status_code == 204

    # Verify
    get_res = client.get(f"/categories/{cat_id}")
    assert get_res.status_code == 404
