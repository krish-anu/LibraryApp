import os
import logging
from typing import Optional

from fastapi import Depends, Header, HTTPException, status

from .database import SessionLocal
from .env import load_app_env


load_app_env()

ASGARDEO_BASE_URL = os.getenv("ASGARDEO_BASE_URL", "")
logger = logging.getLogger(__name__)
DEFAULT_ADMIN_GROUPS = "admin,library-admin,library_admin,Library Administrator"
ROLE_CLAIMS = (
    "groups",
    "roles",
    "role",
    "permissions",
    "scope",
    "http://wso2.org/claims/role",
    "http://wso2.org/claims/roles",
    "http://wso2.org/claims/groups",
)


def _csv_env(name: str, default: str = "") -> set[str]:
    raw = os.getenv(name, default)
    return {part.strip().lower() for part in raw.split(",") if part.strip()}


def _claim_values(value) -> set[str]:
    if value is None:
        return set()
    if isinstance(value, str):
        return {
            part.strip().lower()
            for part in value.replace(",", " ").split()
            if part.strip()
        }
    if isinstance(value, dict):
        values = set()
        for key in ("value", "name", "display", "displayName"):
            item = value.get(key)
            if isinstance(item, str) and item.strip():
                values.add(item.strip().lower())
        return values
    if isinstance(value, (list, tuple, set)):
        values = set()
        for item in value:
            values.update(_claim_values(item))
        return values
    return set()


def identity_subject(identity: dict) -> str:
    subject = str(identity.get("sub") or "").strip()
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Authenticated user is missing subject",
        )
    return subject


def identity_is_admin(identity: dict) -> bool:
    admin_emails = _csv_env("ADMIN_EMAILS")
    user_identifiers = {
        str(identity.get(claim) or "").strip().lower()
        for claim in ("email", "username", "preferred_username")
        if str(identity.get(claim) or "").strip()
    }
    if user_identifiers.intersection(admin_emails):
        return True

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

        return response.json()
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
