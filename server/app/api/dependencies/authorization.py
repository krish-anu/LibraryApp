import logging
from collections.abc import Callable, Iterable

from fastapi import Depends, HTTPException, status

from .identity import (
    identity_admin_matches,
    identity_has_any_scope,
    identity_role_claim_keys,
    identity_scopes,
    identity_subject,
)
from .token import verify_access_token


logger = logging.getLogger(__name__)


def identity_is_admin(identity: dict) -> bool:
    return bool(identity_admin_matches(identity))


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


async def require_admin(identity: dict = Depends(verify_access_token)) -> dict:
    if not identity_is_admin(identity):
        logger.info(
            "Authenticated user is missing admin role; role_claim_keys=%s scopes=%s",
            identity_role_claim_keys(identity),
            sorted(identity_scopes(identity)),
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator privileges are required",
        )
    return identity


def _ensure_any_scope(identity: dict, required_scopes: Iterable[str]) -> None:
    if not identity_has_any_scope(identity, required_scopes):
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
    async def checker(identity: dict = Depends(verify_access_token)) -> dict:
        if not identity_is_admin(identity):
            logger.info(
                "Authenticated user is missing admin role; role_claim_keys=%s scopes=%s",
                identity_role_claim_keys(identity),
                sorted(identity_scopes(identity)),
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Administrator privileges are required",
            )
        _ensure_any_scope(identity, required_scopes)
        return identity

    return checker
