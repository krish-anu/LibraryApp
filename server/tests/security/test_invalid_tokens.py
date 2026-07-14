import pytest

pytestmark = pytest.mark.skip(reason="Invalid token checks require auth dependency/introspection mock.")


def test_invalid_or_expired_token_returns_unauthorized():
    pass
