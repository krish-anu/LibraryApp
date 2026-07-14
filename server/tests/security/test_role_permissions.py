import pytest

pytestmark = pytest.mark.skip(reason="Role/scope matrix scaffold for expanded RBAC coverage.")


def test_manage_scope_without_admin_role_is_denied_for_admin_routes():
    pass
