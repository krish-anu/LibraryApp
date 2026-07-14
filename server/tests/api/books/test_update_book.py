from fastapi.testclient import TestClient


BASE_BOOK = {
    "title": "Before Update",
    "author": "QA Author",
    "category": "Original Category",
    "description": "Before",
    "rating": 4.0,
    "publication_year": 2024,
    "copies_owned": 2,
    "image": "https://example.com/before.jpg",
    "language": "English",
    "pages": 200,
    "rating_count": 3,
}


def test_admin_can_update_book_boundaries(client: TestClient, admin_user):
    created = client.post("/books/", json=BASE_BOOK)
    assert created.status_code == 201
    book_id = created.json()["id"]

    update = {
        **BASE_BOOK,
        "title": "After Update",
        "category": "Updated Category",
        "rating": 5,
        "copies_owned": 0,
        "pages": 1,
    }
    response = client.put(f"/books/{book_id}", json=update)

    assert response.status_code == 200
    body = response.json()
    assert body["title"] == "After Update"
    assert body["category"] == "Updated Category"
    assert body["rating"] == 5
    assert body["copies_owned"] == 0
    assert body["pages"] == 1


def test_update_missing_book_returns_404(client: TestClient, admin_user):
    response = client.put("/books/missing-book", json=BASE_BOOK)

    assert response.status_code == 404
