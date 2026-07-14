from fastapi.testclient import TestClient


def test_search_books_route_is_not_exposed_until_backend_search_exists(
    client: TestClient, admin_user
):
    response = client.get("/books/search", params={"q": "anything"})

    assert response.status_code == 404


def test_books_list_still_returns_seeded_titles_for_client_side_search(
    client: TestClient, admin_user
):
    created = client.post(
        "/books/",
        json={
            "title": "Client Side Search Title",
            "author": "Search Author",
            "category": "Search Category",
            "description": "",
            "rating": 4,
            "publication_year": 2024,
            "copies_owned": 1,
            "image": "https://example.com/search.jpg",
            "language": "English",
            "pages": 140,
            "rating_count": 2,
        },
    )
    assert created.status_code == 201

    response = client.get("/books/")

    assert response.status_code == 200
    assert any(book["title"] == "Client Side Search Title" for book in response.json())
