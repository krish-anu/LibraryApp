import base64
import json
import logging
import os
from json import JSONDecodeError
from typing import Optional

from fastapi import Header, HTTPException

from app.core.env import load_app_env

from .identity import ROLE_CLAIMS, SCOPE_CLAIMS


load_app_env()

ASGARDEO_BASE_URL = os.getenv("ASGARDEO_BASE_URL", "")
ASGARDEO_INTROSPECTION_URL = os.getenv("ASGARDEO_INTROSPECTION_URL", "")
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


def _oauth_url(path: str) -> str:
    return f"{ASGARDEO_BASE_URL.rstrip('/')}/{path.lstrip('/')}"


def _introspection_url() -> str:
    configured_url = ASGARDEO_INTROSPECTION_URL.strip()
    if configured_url:
        return configured_url
    return _oauth_url("/oauth2/introspect")


async def _token_metadata(token: str, client) -> dict:
    if not ASGARDEO_INTROSPECTION_CLIENT_ID or not ASGARDEO_INTROSPECTION_CLIENT_SECRET:
        return {}

    response = await client.post(
        _introspection_url(),
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
        raise HTTPException(
            status_code=503,
            detail="Unable to introspect token with identity provider",
        )

    try:
        metadata = response.json() if response.content else {}
    except JSONDecodeError as exc:
        logger.warning("Asgardeo introspection returned invalid JSON")
        raise HTTPException(
            status_code=503,
            detail="Unable to introspect token with identity provider",
        ) from exc

    if metadata.get("active") is not True:
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


def _jwt_payload(token: str) -> dict:
    parts = token.split(".")
    if len(parts) < 2:
        return {}

    payload = parts[1]
    padding = "=" * (-len(payload) % 4)
    try:
        decoded = base64.urlsafe_b64decode(f"{payload}{padding}")
        data = json.loads(decoded)
    except (ValueError, TypeError, JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def _merge_jwt_claims(identity: dict, token: str) -> dict:
    payload = _jwt_payload(token)
    for claim in (*SCOPE_CLAIMS, *ROLE_CLAIMS):
        if claim in payload and claim not in identity:
            identity[claim] = payload[claim]
    if payload:
        identity["_token_payload_claim_keys"] = sorted(payload.keys())
    return identity


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
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                _oauth_url("/oauth2/userinfo"),
                headers={"Authorization": f"Bearer {token}"},
            )

            if response.status_code != 200:
                raise HTTPException(
                    status_code=401,
                    detail="Invalid or expired access token",
                )

            identity = response.json()
            identity["_access_token"] = token
            _merge_jwt_claims(identity, token)
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
