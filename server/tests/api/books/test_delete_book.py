from fastapi.testclient import TestClient


def test_admin_delete_book_without_dependencies_succeeds(client: TestClient, admin_user):
    created = client.post(
        "/books/",
        json={
            "title": "Delete Me",
            "author": "QA Author",
            "category": "Delete Category",
            "description": "",
            "rating": 2,
            "publication_year": 2024,
            "copies_owned": 1,
            "image": "https://example.com/delete.jpg",
            "language": "English",
            "pages": 120,
            "rating_count": 0,
        },
    )
    assert created.status_code == 201
    book_id = created.json()["id"]

    delete_response = client.delete(f"/books/{book_id}")

    assert delete_response.status_code == 204
    assert client.get(f"/books/{book_id}").status_code == 404


def test_delete_missing_book_returns_404(client: TestClient, admin_user):
    response = client.delete("/books/missing-book")

    assert response.status_code == 404
