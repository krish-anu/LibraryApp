import pytest

pytestmark = pytest.mark.skip(reason="API auth login scaffold; requires mocked Asgardeo userinfo or live test tenant.")


def test_login_with_valid_token_creates_or_syncs_user():
    pass
