from pydantic import ValidationError

from app.pydantic_schemas.book import BookCreate


def test_book_schema_rejects_rating_above_five():
    try:
        BookCreate(title="Bad", author="QA", category="Tech", rating=5.1)
    except ValidationError:
        return
    raise AssertionError("Expected validation error for rating > 5")
