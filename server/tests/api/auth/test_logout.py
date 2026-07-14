import pytest

pytestmark = pytest.mark.skip(reason="API auth logout scaffold; requires mocked Asgardeo revoke endpoint.")


def test_logout_revokes_access_token():
    pass
