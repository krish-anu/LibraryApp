from fastapi.testclient import TestClient


VALID_BOOK = {
    "title": "Create Book Coverage",
    "author": "QA Author",
    "category": "QA Category",
    "description": "Created by API test",
    "rating": 4.2,
    "publication_year": 2024,
    "copies_owned": 3,
    "image": "https://example.com/create-book.jpg",
    "language": "English",
    "pages": 220,
    "rating_count": 7,
}


def test_admin_can_create_valid_book(client: TestClient, admin_user):
    response = client.post("/books/", json=VALID_BOOK)

    assert response.status_code == 201
    body = response.json()
    assert body["id"]
    assert body["title"] == VALID_BOOK["title"]
    assert body["category"] == VALID_BOOK["category"]
    assert body["copies_owned"] == 3


def test_create_book_rejects_invalid_boundaries(client: TestClient, admin_user):
    payload = {**VALID_BOOK, "rating": 6, "pages": 0}

    response = client.post("/books/", json=payload)

    assert response.status_code == 422
