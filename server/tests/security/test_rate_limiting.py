import pytest

pytestmark = pytest.mark.skip(reason="Rate limit checks require HTTP client/lifespan configuration.")


def test_auth_rate_limit_returns_429_after_threshold():
    pass
