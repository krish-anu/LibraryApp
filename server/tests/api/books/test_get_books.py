from fastapi.testclient import TestClient


def test_user_with_books_read_scope_can_list_books(client: TestClient, admin_user):
    created = client.post(
        "/books/",
        json={
            "title": "Readable Book",
            "author": "QA Author",
            "category": "Read Scope",
            "description": "",
            "rating": 3.5,
            "publication_year": 2024,
            "copies_owned": 1,
            "image": "https://example.com/readable.jpg",
            "language": "English",
            "pages": 180,
            "rating_count": 1,
        },
    )
    assert created.status_code == 201

    response = client.get("/books/")

    assert response.status_code == 200
    assert any(book["title"] == "Readable Book" for book in response.json())


def test_get_missing_book_returns_404(client: TestClient, admin_user):
    response = client.get("/books/not-a-real-book")

    assert response.status_code == 404
    assert response.json()["detail"] == "Book not found"
