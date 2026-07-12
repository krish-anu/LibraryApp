import os
import logging
from typing import Callable, Iterable, Optional

from fastapi import Depends, Header, HTTPException, status

from .database import SessionLocal
from .env import load_app_env


load_app_env()

ASGARDEO_BASE_URL = os.getenv("ASGARDEO_BASE_URL", "")
ASGARDEO_INTROSPECTION_CLIENT_ID = (
    os.getenv("ASGARDEO_INTROSPECTION_CLIENT_ID")
    or os.getenv("ASGARDEO_PUBLIC_CLIENT_ID")
    or os.getenv("ASGARDEO_CLIENT_ID")
    or ""
)
ASGARDEO_INTROSPECTION_CLIENT_SECRET = (
    os.getenv("ASGARDEO_INTROSPECTION_CLIENT_SECRET")
    or os.getenv("ASGARDEO_PUBLIC_CLIENT_SECRET")
    or os.getenv("ASGARDEO_CLIENT_SECRET")
    or ""
)
logger = logging.getLogger(__name__)
DEFAULT_ADMIN_GROUPS = "admin,library-admin,library_admin,Library Administrator"
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


def _claim_values(value) -> set[str]:
    def normalize(raw: str) -> set[str]:
        normalized = raw.strip().lower()
        if not normalized:
            return set()
        values = {normalized}
        for separator in ("/", ":", "|"):
            for part in normalized.split(separator):
                part = part.strip()
                if part:
                    values.add(part)
        return values

    if value is None:
        return set()
    if isinstance(value, str):
        values = set()
        for part in value.replace(",", " ").split():
            values.update(normalize(part))
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
            item = value.get(key)
            values.update(_claim_values(item))
        return values
    if isinstance(value, (list, tuple, set)):
        values = set()
        for item in value:
            values.update(_claim_values(item))
        return values
    return set()


def _normalize_scope(raw: str) -> set[str]:
    normalized = raw.strip().lower()
    if not normalized:
        return set()
    return {
        normalized,
        normalized.replace(":", "_"),
    }


def _scope_values(value) -> set[str]:
    if value is None:
        return set()
    if isinstance(value, str):
        values = set()
        for part in value.replace(",", " ").split():
            values.update(_normalize_scope(part))
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


async def _token_metadata(token: str, client) -> dict:
    if not ASGARDEO_INTROSPECTION_CLIENT_ID or not ASGARDEO_INTROSPECTION_CLIENT_SECRET:
        return {}

    response = await client.post(
        f"{ASGARDEO_BASE_URL}/oauth2/introspect",
        data={"token": token},
        auth=(
            ASGARDEO_INTROSPECTION_CLIENT_ID,
            ASGARDEO_INTROSPECTION_CLIENT_SECRET,
        ),
        headers={"Accept": "application/json"},
    )
    if response.status_code != 200:
        logger.warning(
            "Failed to introspect token with Asgardeo: status %s",
            response.status_code,
        )
        return {}

    metadata = response.json() if response.content else {}
    if metadata.get("active") is False:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired access token",
        )
    return metadata


def _merge_token_metadata(identity: dict, metadata: dict) -> dict:
    for claim in (*SCOPE_CLAIMS, *ROLE_CLAIMS):
        if claim in metadata and claim not in identity:
            identity[claim] = metadata[claim]
    if metadata:
        identity["_token_metadata"] = metadata
    return identity


def identity_subject(identity: dict) -> str:
    subject = str(identity.get("sub") or "").strip()
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Authenticated user is missing subject",
        )
    return subject


def identity_is_admin(identity: dict) -> bool:
    allowed_roles = _csv_env("ADMIN_GROUPS", DEFAULT_ADMIN_GROUPS)
    claim_values = set()
    for claim in ROLE_CLAIMS:
        claim_values.update(_claim_values(identity.get(claim)))
    return bool(claim_values.intersection(allowed_roles))


def require_subject_or_admin(identity: dict, requested_subject: str) -> None:
    requested = str(requested_subject or "").strip()
    if requested and identity_subject(identity) == requested:
        return
    if identity_is_admin(identity):
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="You are not allowed to access this resource",
    )


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def verify_access_token(
    authorization: Optional[str] = Header(default=None),
) -> dict:
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Missing Authorization header",
        )

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=401,
            detail="Invalid Authorization header format. Expected: Bearer <token>",
        )

    token = parts[1]

    if not ASGARDEO_BASE_URL:
        raise HTTPException(
            status_code=503,
            detail="Identity provider not configured",
        )

    import httpx

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{ASGARDEO_BASE_URL}/oauth2/userinfo",
                headers={"Authorization": f"Bearer {token}"},
            )

            if response.status_code != 200:
                raise HTTPException(
                    status_code=401,
                    detail="Invalid or expired access token",
                )

            identity = response.json()
            identity["_access_token"] = token
            metadata = await _token_metadata(token, client)
            _merge_token_metadata(identity, metadata)
            return identity
    except httpx.RequestError as exc:
        logger.warning(
            "Failed to verify token with Asgardeo userinfo endpoint %s/oauth2/userinfo: %s",
            ASGARDEO_BASE_URL,
            exc,
        )
        raise HTTPException(
            status_code=503,
            detail="Unable to verify token with identity provider",
        ) from exc


async def require_admin(identity: dict = Depends(verify_access_token)) -> dict:
    if not identity_is_admin(identity):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator privileges are required",
        )
    return identity


def _ensure_any_scope(identity: dict, required_scopes: Iterable[str]) -> None:
    required = set()
    for scope in required_scopes:
        required.update(_normalize_scope(scope))

    granted = identity_scopes(identity)
    if not granted.intersection(required):
        display = ", ".join(sorted(required_scopes))
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Missing required scope: {display}",
        )


def require_scope(*required_scopes: str) -> Callable:
    async def checker(identity: dict = Depends(verify_access_token)) -> dict:
        _ensure_any_scope(identity, required_scopes)
        return identity

    return checker


def require_admin_scope(*required_scopes: str) -> Callable:
    async def checker(identity: dict = Depends(require_admin)) -> dict:
        _ensure_any_scope(identity, required_scopes)
        return identity

    return checker
