from app.api.dependencies.authorization import identity_is_admin


def test_identity_is_admin_detects_admin_group():
    assert identity_is_admin({"sub": "admin", "groups": ["admin"]}) is True
    assert identity_is_admin({"sub": "member", "groups": []}) is False
