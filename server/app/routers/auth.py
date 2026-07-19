"""
Asgardeo Authentication Router

This router handles user registration via Asgardeo's SCIM2 API.
For public mobile clients, registration must go through a backend service
that has the necessary credentials to create users.
"""

import base64
import hashlib
import os
import secrets
import httpx
import logging
from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel, EmailStr
from typing import Optional
from sqlalchemy.orm import Session
from datetime import date

from app.api.dependencies import (
    get_db,
    identity_admin_matches,
    identity_is_admin,
    identity_member_matches,
    identity_role_claim_keys,
    identity_role_values,
    identity_scopes,
    verify_access_token,
)
from app.core.env import load_app_env
from app.models.users import User as UserModel
from app.pydantic_schemas import user as user_schema
from app.core.security import create_limiter

load_app_env()

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger(__name__)

# Rate limiter for auth endpoints (stricter than general API)
limiter = create_limiter()
AUTH_REGISTER_RATE_LIMIT = os.getenv("AUTH_REGISTER_RATE_LIMIT", "5/minute")
AUTH_CREDENTIAL_LOGIN_RATE_LIMIT = os.getenv(
    "AUTH_CREDENTIAL_LOGIN_RATE_LIMIT", "10/minute"
)

# Asgardeo Configuration - Read from environment variables
ASGARDEO_BASE_URL = os.getenv("ASGARDEO_BASE_URL", "")
if not ASGARDEO_BASE_URL:
    import warnings

    warnings.warn(
        "ASGARDEO_BASE_URL environment variable is not set. Auth endpoints will fail at runtime."
    )
# This is your M2M (Machine-to-Machine) application credentials for the backend
ASGARDEO_M2M_CLIENT_ID = os.getenv("ASGARDEO_M2M_CLIENT_ID", "")
ASGARDEO_M2M_CLIENT_SECRET = os.getenv("ASGARDEO_M2M_CLIENT_SECRET", "")
# Public client id used by mobile apps (for token revocation)
ASGARDEO_PUBLIC_CLIENT_ID = os.getenv("ASGARDEO_PUBLIC_CLIENT_ID", "")
ASGARDEO_PUBLIC_CLIENT_SECRET = os.getenv("ASGARDEO_PUBLIC_CLIENT_SECRET", "")
ASGARDEO_REDIRECT_URL = os.getenv(
    "ASGARDEO_REDIRECT_URL", "com.focus.libraryapp://callback"
)
ASGARDEO_SCOPE = os.getenv(
    "ASGARDEO_SCOPE",
    "openid profile email groups roles "
    "dashboard_read books_read books_manage content_read content_manage "
    "categories_read categories_manage loans_read loans_manage "
    "reservations_read reservations_manage favorites_read favorites_manage "
    "users_read users_manage fines_read fines_manage "
    "notifications_read notifications_manage settings_read settings_manage",
)
DEFAULT_ADMIN_GROUPS = "admin,library-admin,library_admin,Library Administrator"


def _configured_admin_groups() -> list[str]:
    raw = os.getenv("ADMIN_GROUPS", DEFAULT_ADMIN_GROUPS)
    return sorted({part.strip().lower() for part in raw.split(",") if part.strip()})


class RegisterRequest(BaseModel):
    """Registration request schema."""

    email: EmailStr
    password: str
    first_name: str
    last_name: str
    username: Optional[str] = None
    phone_number: Optional[str] = None

    @classmethod
    def validate_password_strength(cls, password: str) -> str:
        if len(password) < 8:
            raise ValueError("Password must be at least 8 characters long")
        if not any(c.isupper() for c in password):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in password):
            raise ValueError("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in password):
            raise ValueError("Password must contain at least one digit")
        return password


class RegisterResponse(BaseModel):
    """Registration response schema."""

    success: bool
    message: str
    user_id: Optional[str] = None


class AsgardeoLoginRequest(BaseModel):
    """Asgardeo login sync request schema."""

    access_token: str


class AsgardeoLoginResponse(BaseModel):
    """Asgardeo login sync response schema."""

    success: bool
    created: bool
    user_id: str
    user: user_schema.User


class AsgardeoLogoutRequest(BaseModel):
    """Asgardeo logout request schema."""

    access_token: str


class AsgardeoLogoutResponse(BaseModel):
    """Asgardeo logout response schema."""

    success: bool


class CredentialLoginRequest(BaseModel):
    """Login using email/password (backend verifies with Asgardeo)."""

    email: EmailStr
    password: str


class CredentialLoginResponse(BaseModel):
    """Response returned after credential login and local user sync."""

    success: bool
    created: bool
    user_id: str
    user: user_schema.User
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None


class IdentityDebugResponse(BaseModel):
    """Safe auth diagnostic response. Never includes access tokens or secrets."""

    subject_present: bool
    is_admin: bool
    configured_admin_groups: list[str]
    matched_admin_values: list[str]
    role_claim_keys_present: list[str]
    role_values_seen: list[str]
    scopes_seen: list[str]


def _pkce_verifier() -> str:
    return secrets.token_urlsafe(64)


def _pkce_challenge(verifier: str) -> str:
    digest = hashlib.sha256(verifier.encode("ascii")).digest()
    return base64.urlsafe_b64encode(digest).decode("ascii").rstrip("=")


def _flow_error(data: dict, fallback: str) -> str:
    next_step = data.get("nextStep")
    if isinstance(next_step, dict):
        messages = next_step.get("messages")
        if isinstance(messages, list):
            for item in messages:
                if isinstance(item, dict):
                    message = str(item.get("message") or "").strip()
                    if message:
                        return message

    return str(
        data.get("error_description")
        or data.get("description")
        or data.get("message")
        or data.get("error")
        or fallback
    )


def _username_password_authenticator(data: dict) -> str | None:
    next_step = data.get("nextStep")
    if not isinstance(next_step, dict):
        return None

    authenticators = next_step.get("authenticators")
    if not isinstance(authenticators, list):
        return None

    for item in authenticators:
        if not isinstance(item, dict):
            continue
        required_params = item.get("requiredParams")
        if (
            isinstance(required_params, list)
            and "username" in required_params
            and "password" in required_params
        ):
            authenticator_id = str(item.get("authenticatorId") or "").strip()
            if authenticator_id:
                return authenticator_id

    return None


async def _credentials_to_asgardeo_token(payload: CredentialLoginRequest) -> dict:
    if not ASGARDEO_BASE_URL:
        raise HTTPException(
            status_code=503,
            detail="Identity provider not configured. Set ASGARDEO_BASE_URL in .env",
        )
    if not ASGARDEO_PUBLIC_CLIENT_ID:
        raise HTTPException(
            status_code=500,
            detail="Server configuration error: ASGARDEO_PUBLIC_CLIENT_ID not configured.",
        )

    verifier = _pkce_verifier()
    state = secrets.token_urlsafe(32)

    async with httpx.AsyncClient(timeout=20.0) as client:
        initiation_response = await client.post(
            f"{ASGARDEO_BASE_URL}/oauth2/authorize/",
            data={
                "client_id": ASGARDEO_PUBLIC_CLIENT_ID,
                "response_type": "code",
                "redirect_uri": ASGARDEO_REDIRECT_URL,
                "scope": ASGARDEO_SCOPE,
                "response_mode": "direct",
                "state": state,
                "code_challenge": _pkce_challenge(verifier),
                "code_challenge_method": "S256",
            },
            headers={
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )

        initiation = initiation_response.json() if initiation_response.content else {}
        if initiation_response.status_code != 200 or not isinstance(initiation, dict):
            raise HTTPException(
                status_code=502,
                detail=_flow_error(
                    initiation if isinstance(initiation, dict) else {},
                    "Unable to start Asgardeo credential login flow.",
                ),
            )

        flow_id = str(initiation.get("flowId") or "").strip()
        authenticator_id = _username_password_authenticator(initiation)
        if not flow_id or not authenticator_id:
            raise HTTPException(
                status_code=400,
                detail=_flow_error(
                    initiation,
                    "Username and password authentication is not available in the configured Asgardeo login flow.",
                ),
            )

        authn_response = await client.post(
            f"{ASGARDEO_BASE_URL}/oauth2/authn",
            json={
                "flowId": flow_id,
                "selectedAuthenticator": {
                    "authenticatorId": authenticator_id,
                    "params": {
                        "username": payload.email,
                        "password": payload.password,
                    },
                },
            },
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
            },
        )

        authn = authn_response.json() if authn_response.content else {}
        if authn_response.status_code in (400, 401, 403):
            raise HTTPException(
                status_code=401,
                detail=_flow_error(authn, "Invalid email or password."),
            )
        if authn_response.status_code != 200 or not isinstance(authn, dict):
            raise HTTPException(
                status_code=502,
                detail=_flow_error(authn, "Asgardeo credential login failed."),
            )

        auth_data = authn.get("authData")
        code = (
            auth_data.get("code")
            if isinstance(auth_data, dict)
            else authn.get("code")
        )
        code = str(code or "").strip()
        if authn.get("flowStatus") != "SUCCESS_COMPLETED" or not code:
            raise HTTPException(
                status_code=401,
                detail=_flow_error(
                    authn,
                    "Sign in requires an additional authentication step that this endpoint does not support.",
                ),
            )

        token_body = {
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": ASGARDEO_REDIRECT_URL,
            "client_id": ASGARDEO_PUBLIC_CLIENT_ID,
            "code_verifier": verifier,
        }
        if ASGARDEO_PUBLIC_CLIENT_SECRET:
            token_body["client_secret"] = ASGARDEO_PUBLIC_CLIENT_SECRET

        token_response = await client.post(
            f"{ASGARDEO_BASE_URL}/oauth2/token",
            data=token_body,
            headers={
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )
        token_data = token_response.json() if token_response.content else {}
        if token_response.status_code != 200 or not isinstance(token_data, dict):
            raise HTTPException(
                status_code=502,
                detail=_flow_error(token_data, "Unable to exchange Asgardeo login code for access token."),
            )
        if not token_data.get("access_token"):
            raise HTTPException(
                status_code=502,
                detail="Asgardeo token response did not include an access token.",
            )

        return token_data


async def get_client_credentials_token() -> Optional[str]:
    """Get an access token using client credentials grant from M2M app."""
    if not ASGARDEO_M2M_CLIENT_ID or not ASGARDEO_M2M_CLIENT_SECRET:
        logger.error(
            "M2M credentials not configured. Set ASGARDEO_M2M_CLIENT_ID and ASGARDEO_M2M_CLIENT_SECRET environment variables."
        )
        return None

    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.post(
            f"{ASGARDEO_BASE_URL}/oauth2/token",
            data={
                "grant_type": "client_credentials",
                "client_id": ASGARDEO_M2M_CLIENT_ID,
                "client_secret": ASGARDEO_M2M_CLIENT_SECRET,
                "scope": "internal_user_mgt_create internal_user_mgt_view internal_org_user_mgt_create internal_org_user_mgt_list",
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )

        if response.status_code != 200:
            logger.warning("Token request failed with status %s", response.status_code)

        if response.status_code == 200:
            data = response.json()
            return data.get("access_token")

        return None


@router.get("/debug/identity", response_model=IdentityDebugResponse)
async def debug_identity(identity: dict = Depends(verify_access_token)):
    """Return non-secret auth claim details for local Postman troubleshooting."""

    return IdentityDebugResponse(
        subject_present=bool(str(identity.get("sub") or "").strip()),
        is_admin=identity_is_admin(identity),
        configured_admin_groups=_configured_admin_groups(),
        matched_admin_values=sorted(identity_admin_matches(identity)),
        role_claim_keys_present=identity_role_claim_keys(identity),
        role_values_seen=sorted(identity_role_values(identity)),
        scopes_seen=sorted(identity_scopes(identity)),
    )


@router.post("/register", response_model=RegisterResponse)
@limiter.limit(AUTH_REGISTER_RATE_LIMIT)
async def register_user(request: Request, payload: RegisterRequest):
    """
    Register a new user via Asgardeo API.

    This endpoint allows mobile clients to register users without
    needing confidential client credentials on the device.
    """

    # Validate password strength
    try:
        RegisterRequest.validate_password_strength(payload.password)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    admin_token = await get_client_credentials_token()

    if not admin_token:
        raise HTTPException(
            status_code=500,
            detail="Server configuration error: M2M credentials not configured or invalid.",
        )

    async with httpx.AsyncClient(timeout=20.0) as client:
        # Try 1: Asgardeo User Management API
        user_mgmt_body = {
            "userName": payload.email,
            "password": payload.password,
            "name": {
                "givenName": payload.first_name,
                "familyName": payload.last_name,
            },
            "emails": [payload.email],
        }

        if payload.phone_number:
            user_mgmt_body["phoneNumbers"] = [payload.phone_number]

        response = await client.post(
            f"{ASGARDEO_BASE_URL}/api/users/v1",
            json=user_mgmt_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": f"Bearer {admin_token}",
            },
        )

        if response.status_code in [200, 201]:
            data = response.json() if response.content else {}
            return RegisterResponse(
                success=True,
                message="Registration successful! Please login.",
                user_id=data.get("id"),
            )

        if response.status_code == 409:
            raise HTTPException(
                status_code=409, detail="A user with this email already exists."
            )

        # Try 2: SCIM2 with organization prefix /o/scim2/Users
        scim_user = {
            "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
            "userName": payload.email,
            "password": payload.password,
            "name": {
                "givenName": payload.first_name,
                "familyName": payload.last_name,
            },
            "emails": [{"value": payload.email, "primary": True}],
        }

        if payload.phone_number:
            scim_user["phoneNumbers"] = [
                {"value": payload.phone_number, "type": "mobile"}
            ]

        response = await client.post(
            f"{ASGARDEO_BASE_URL}/o/scim2/Users",
            json=scim_user,
            headers={
                "Content-Type": "application/scim+json",
                "Accept": "application/scim+json",
                "Authorization": f"Bearer {admin_token}",
            },
        )

        if response.status_code in [200, 201]:
            data = response.json()
            return RegisterResponse(
                success=True,
                message="Registration successful! Please login.",
                user_id=data.get("id"),
            )

        if response.status_code == 409:
            raise HTTPException(
                status_code=409, detail="A user with this email already exists."
            )

        # Try 3: Regular SCIM2 /scim2/Users
        response = await client.post(
            f"{ASGARDEO_BASE_URL}/scim2/Users",
            json=scim_user,
            headers={
                "Content-Type": "application/scim+json",
                "Accept": "application/scim+json",
                "Authorization": f"Bearer {admin_token}",
            },
        )

        if response.status_code in [200, 201]:
            data = response.json()
            return RegisterResponse(
                success=True,
                message="Registration successful! Please login.",
                user_id=data.get("id"),
            )

        if response.status_code == 409:
            raise HTTPException(
                status_code=409, detail="A user with this email already exists."
            )

        # All methods failed
        error_data = response.json() if response.content else {}
        error_msg = (
            error_data.get("detail")
            or error_data.get("scimType")
            or error_data.get("message")
            or error_data.get("description")
            or "Registration failed"
        )

        raise HTTPException(status_code=400, detail=error_msg)


async def _ensure_user_from_access_token(
    access_token: str, db: Session
) -> tuple[UserModel, bool]:
    if not ASGARDEO_BASE_URL:
        raise HTTPException(
            status_code=503,
            detail="Identity provider not configured. Set ASGARDEO_BASE_URL in .env",
        )

    try:
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                f"{ASGARDEO_BASE_URL}/oauth2/userinfo",
                headers={"Authorization": f"Bearer {access_token}"},
            )
    except httpx.RequestError as e:
        logger.warning(
            "Failed to reach Asgardeo userinfo endpoint %s/oauth2/userinfo: %s",
            ASGARDEO_BASE_URL,
            e,
        )
        raise HTTPException(
            status_code=503,
            detail="Unable to reach identity provider",
        )

    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid Asgardeo access token")

    data = response.json() if response.content else {}
    sub = data.get("sub")
    if not sub:
        raise HTTPException(
            status_code=400, detail="Asgardeo user info missing subject"
        )
    if identity_is_admin(data):
        logger.info(
            "Rejected administrator account on member login; role_claim_keys=%s",
            identity_role_claim_keys(data),
        )
        raise HTTPException(
            status_code=403,
            detail="Administrator accounts can only sign in to the admin portal.",
        )
    if not identity_member_matches(data):
        logger.info(
            "Rejected non-member account on member login; role_claim_keys=%s role_values=%s",
            identity_role_claim_keys(data),
            sorted(identity_role_values(data)),
        )
        raise HTTPException(
            status_code=403,
            detail="Member role is required to sign in to the mobile app.",
        )

    email = data.get("email")
    given_name = data.get("given_name")
    family_name = data.get("family_name")
    username = data.get("username") or data.get("preferred_username")
    name_parts = [p for p in [given_name, family_name] if p]
    name = " ".join(name_parts) if name_parts else (username or email or "")
    phone = data.get("phone_number")
    picture = data.get("picture")

    address = None
    raw_address = data.get("address")
    if isinstance(raw_address, dict):
        address = raw_address.get("formatted") or raw_address.get("street_address")

    user = None
    created = False
    try:
        user = db.query(UserModel).filter(UserModel.id == sub).first()
        if not user:
            user = UserModel(
                id=sub,
                member_id=sub,
                name=name,
                email=email,
                phone=phone,
                address=address,
                profile_image=picture,
                joined_date=date.today(),
                password=None,
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            created = True
    except Exception:
        try:
            db.rollback()
        except Exception as rollback_error:
            logger.warning("Database rollback failed: %s", rollback_error)
        logger.exception("Exception while ensuring or creating local user")
        raise HTTPException(
            status_code=500,
            detail="An internal error occurred. Please try again later.",
        )

    return user, created


@router.post("/login", response_model=AsgardeoLoginResponse)
async def login_user_via_asgardeo(
    request: AsgardeoLoginRequest, db: Session = Depends(get_db)
):
    """
    Verify Asgardeo access token, then ensure the user exists in the local DB.
    If the user doesn't exist, create one using Asgardeo user info.
    """

    user, created = await _ensure_user_from_access_token(request.access_token, db)
    return AsgardeoLoginResponse(
        success=True,
        created=created,
        user_id=str(user.id),
        user=user_schema.User.model_validate(user),
    )


@router.post("/asgardeo/login", response_model=AsgardeoLoginResponse)
async def asgardeo_login_sync(
    request: AsgardeoLoginRequest, db: Session = Depends(get_db)
):
    """Backward-compatible alias for /auth/login."""

    user, created = await _ensure_user_from_access_token(request.access_token, db)
    return AsgardeoLoginResponse(
        success=True,
        created=created,
        user_id=str(user.id),
        user=user_schema.User.model_validate(user),
    )


@router.post("/login/credentials", response_model=CredentialLoginResponse)
@limiter.limit(AUTH_CREDENTIAL_LOGIN_RATE_LIMIT)
async def login_with_credentials(
    payload: CredentialLoginRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    """Validate credentials with Asgardeo App-Native Auth, then sync local user."""

    token_data = await _credentials_to_asgardeo_token(payload)
    access_token = token_data["access_token"]
    user, created = await _ensure_user_from_access_token(access_token, db)

    return CredentialLoginResponse(
        success=True,
        created=created,
        user_id=str(user.id),
        user=user_schema.User.model_validate(user),
        access_token=access_token,
        refresh_token=token_data.get("refresh_token"),
    )


@router.post("/logout", response_model=AsgardeoLogoutResponse)
async def logout_user_via_asgardeo(request: AsgardeoLogoutRequest):
    """
    Revoke Asgardeo access token.
    """

    if not ASGARDEO_PUBLIC_CLIENT_ID:
        raise HTTPException(
            status_code=500,
            detail="Server configuration error: ASGARDEO_PUBLIC_CLIENT_ID not configured.",
        )

    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.post(
            f"{ASGARDEO_BASE_URL}/oauth2/revoke",
            data={
                "token": request.access_token,
                "client_id": ASGARDEO_PUBLIC_CLIENT_ID,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )

    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Failed to revoke token")

    return AsgardeoLogoutResponse(success=True)
