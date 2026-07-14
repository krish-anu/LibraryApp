import pytest

pytestmark = pytest.mark.skip(reason="Expanded HTTP API scaffold; list coverage exists in current server tests.")


def test_user_with_books_read_scope_can_list_books():
    pass
