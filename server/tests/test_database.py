import pytest
from sqlalchemy.exc import IntegrityError
from app.models.book import Book
from app.models.category import Category

def test_foreign_key_constraint(db_session):
    """DB-01: Foreign key integrity"""
    book = Book(
        id="fake-id",
        title="No Category Book",
        pages=100,
        copies_owned=1,
        language="en",
        publication_year=2020,
        author_id="Me",
        description="desc",
        category_id="99999",  # Invalid
    )
    db_session.add(book)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()

def test_unique_constraint(db_session):
    """DB-05: Unique constraints enforcement (e.g. ISBN or Category Name)"""
    # Create category
    c1 = Category(id="cat1", name="Unique Cat", image_url="http://img")
    db_session.add(c1)
    db_session.commit()

    # Try duplicate id or name depending on uniqueness
    c2 = Category(id="cat1", name="Unique Cat", image_url="http://img2")
    db_session.add(c2)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()

def test_nullable_constraint(db_session):
    """DB-06: Nullable vs non-nullable. id is pk."""
    # Assuming id is non-nullable but we send None or it doesn't default
    c = Category(name="No name", image_url="http://img")
    db_session.add(c)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()
