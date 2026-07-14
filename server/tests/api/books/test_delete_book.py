import pytest

pytestmark = pytest.mark.skip(reason="Expanded HTTP API scaffold; delete dependency rules need product clarification.")


def test_admin_delete_book_without_dependencies_succeeds():
    pass
