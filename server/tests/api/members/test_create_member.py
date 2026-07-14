import pytest

pytestmark = pytest.mark.skip(reason="Expanded HTTP API scaffold; user creation checks exist in current tests.")


def test_admin_can_create_member_with_unique_email():
    pass
