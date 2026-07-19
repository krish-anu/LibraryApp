import os
from collections.abc import Iterable

from fastapi import HTTPException, status


DEFAULT_ADMIN_GROUPS = "Admin"
DEFAULT_MEMBER_GROUPS = "User"
ROLE_CLAIMS = (
    "groups",
    "roles",
    "role",
    "app_roles",
    "appRoles",
    "application_roles",
    "applicationRoles",
    "assigned_roles",
    "assignedRoles",
    "groups_display",
    "groupsDisplay",
    "member_of",
    "memberOf",
    "http://wso2.org/claims/role",
    "http://wso2.org/claims/roles",
    "http://wso2.org/claims/groups",
    "http://wso2.org/claims/applicationRoles",
    "http://wso2.org/claims/application_roles",
)
SCOPE_CLAIMS = (
    "scope",
    "scp",
    "scopes",
    "permissions",
    "permission",
    "http://wso2.org/claims/permissions",
    "http://wso2.org/claims/scope",
)


def _csv_env(name: str, default: str = "") -> set[str]:
    raw = os.getenv(name, default)
    return {part.strip().lower() for part in raw.split(",") if part.strip()}


def _split_claim(raw: str) -> set[str]:
    normalized = raw.strip().lower()
    if not normalized:
        return set()

    values = {normalized}
    for separator in ("/", ":", "|"):
        values.update(part.strip() for part in normalized.split(separator) if part.strip())
    return values


def _claim_values(value) -> set[str]:
    if value is None:
        return set()
    if isinstance(value, str):
        values = set()
        for part in value.replace(",", " ").split():
            values.update(_split_claim(part))
        return values
    if isinstance(value, dict):
        values = set()
        for item in value.values():
            values.update(_claim_values(item))
        for key in (
            "value",
            "name",
            "display",
            "displayName",
            "role",
            "roles",
            "roleName",
            "group",
            "groups",
            "groupName",
        ):
            values.update(_claim_values(value.get(key)))
        return values
    if isinstance(value, (list, tuple, set)):
        values = set()
        for item in value:
            values.update(_claim_values(item))
        return values
    return set()


def normalize_scope(raw: str) -> set[str]:
    normalized = raw.strip().lower()
    if not normalized:
        return set()
    return {normalized, normalized.replace(":", "_")}


def _scope_values(value) -> set[str]:
    if value is None:
        return set()
    if isinstance(value, str):
        values = set()
        for part in value.replace(",", " ").split():
            values.update(normalize_scope(part))
        return values
    if isinstance(value, dict):
        values = set()
        for key in ("value", "name", "display", "displayName"):
            item = value.get(key)
            if isinstance(item, str) and item.strip():
                values.update(_scope_values(item))
        return values
    if isinstance(value, (list, tuple, set)):
        values = set()
        for item in value:
            values.update(_scope_values(item))
        return values
    return set()


def identity_scopes(identity: dict) -> set[str]:
    scopes = set()
    for claim in SCOPE_CLAIMS:
        scopes.update(_scope_values(identity.get(claim)))
    return scopes


def identity_has_any_scope(identity: dict, required_scopes: Iterable[str]) -> bool:
    required = set()
    for scope in required_scopes:
        required.update(normalize_scope(scope))
    return bool(identity_scopes(identity).intersection(required))


def identity_role_values(identity: dict) -> set[str]:
    values = set()
    for claim in ROLE_CLAIMS:
        values.update(_claim_values(identity.get(claim)))
    return values


def identity_role_claim_keys(identity: dict) -> list[str]:
    return sorted(claim for claim in ROLE_CLAIMS if identity.get(claim) is not None)


def identity_admin_matches(identity: dict) -> set[str]:
    allowed_roles = _csv_env("ADMIN_GROUPS", DEFAULT_ADMIN_GROUPS)
    matches = identity_role_values(identity).intersection(allowed_roles)

    allowed_emails = _csv_env("ADMIN_EMAILS")
    for claim in (
        "email",
        "username",
        "preferred_username",
        "userName",
        "http://wso2.org/claims/emailaddress",
        "http://wso2.org/claims/email",
        "http://wso2.org/claims/username",
    ):
        value = str(identity.get(claim) or "").strip().lower()
        if value and value in allowed_emails:
            matches.add(value)

    allowed_subjects = _csv_env("ADMIN_SUBJECTS")
    subject = str(identity.get("sub") or "").strip().lower()
    if subject and subject in allowed_subjects:
        matches.add(subject)

    return matches


def identity_member_matches(identity: dict) -> set[str]:
    allowed_roles = _csv_env("MEMBER_GROUPS", DEFAULT_MEMBER_GROUPS)
    return identity_role_values(identity).intersection(allowed_roles)


def identity_subject(identity: dict) -> str:
    subject = str(identity.get("sub") or "").strip()
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Authenticated user is missing subject",
        )
    return subject
