import pytest

pytestmark = pytest.mark.skip(reason="Automatic fine calculation requirement is not documented yet.")


def test_overdue_fine_uses_grace_rate_and_cap_settings():
    pass
