import pytest

pytestmark = pytest.mark.skip(reason="Refresh token endpoint is not implemented; retained for requirement tracking.")


def test_refresh_token_rotates_session_tokens():
    pass
