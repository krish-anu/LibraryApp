"""Compatibility exports for legacy imports.

New code should import from ``app.api.dependencies`` directly.
"""

from app.api.dependencies import (
    get_db,
    identity_admin_matches,
    identity_has_any_scope,
    identity_is_admin,
    identity_role_claim_keys,
    identity_role_values,
    identity_scopes,
    identity_subject,
    require_admin,
    require_admin_scope,
    require_scope,
    require_subject_or_admin,
    verify_access_token,
)


__all__ = [
    "get_db",
    "identity_admin_matches",
    "identity_has_any_scope",
    "identity_is_admin",
    "identity_role_claim_keys",
    "identity_role_values",
    "identity_scopes",
    "identity_subject",
    "require_admin",
    "require_admin_scope",
    "require_scope",
    "require_subject_or_admin",
    "verify_access_token",
]
