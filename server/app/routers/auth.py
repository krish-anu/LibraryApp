"""
Asgardeo Authentication Router

This router handles user registration via Asgardeo's SCIM2 API.
For public mobile clients, registration must go through a backend service
that has the necessary credentials to create users.
"""

import os
import httpx
import logging
import traceback
from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel, EmailStr
from typing import Optional
from sqlalchemy.orm import Session
from datetime import date

from app.dependencies import get_db
from app.env import load_app_env
from app.models.users import User as UserModel
from app.pydantic_schemas import user as user_schema
from app.security import create_limiter

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


async def get_client_credentials_token() -> Optional[str]:
    """Get an access token using client credentials grant from M2M app."""
    if not ASGARDEO_M2M_CLIENT_ID or not ASGARDEO_M2M_CLIENT_SECRET:
        print(
            "M2M credentials not configured. Set ASGARDEO_M2M_CLIENT_ID and ASGARDEO_M2M_CLIENT_SECRET environment variables."
        )
        return None

    async with httpx.AsyncClient() as client:
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

        print(f"Token request status: {response.status_code}")
        if response.status_code != 200:
            print("Token request failed")

        if response.status_code == 200:
            data = response.json()
            return data.get("access_token")

        return None


@router.post("/register", response_model=RegisterResponse)
@limiter.limit(AUTH_REGISTER_RATE_LIMIT)
async def register_user(payload: RegisterRequest, request: Request = None):
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

    async with httpx.AsyncClient() as client:
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
        async with httpx.AsyncClient() as client:
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
        except Exception:
            pass
        print("Exception while ensuring/creating local user:")
        traceback.print_exc()
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
    request: Request = None,
    db: Session = Depends(get_db),
):
    """Validate email/password with Asgardeo, then ensure local user exists.

    This endpoint performs a resource-owner password token request against
    Asgardeo and uses the returned access token to fetch userinfo and
    create/sync the user in the local `users` table.
    """

    if not ASGARDEO_PUBLIC_CLIENT_ID:
        raise HTTPException(
            status_code=500,
            detail="Server configuration error: ASGARDEO_PUBLIC_CLIENT_ID not configured.",
        )

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{ASGARDEO_BASE_URL}/oauth2/token",
            data={
                "grant_type": "password",
                "username": payload.email,
                "password": payload.password,
                "client_id": ASGARDEO_PUBLIC_CLIENT_ID,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )

    if response.status_code != 200:
        detail = None
        try:
            detail = response.json().get("error_description") or response.json().get(
                "error"
            )
        except Exception:
            detail = response.text or "Authentication failed"

        raise HTTPException(status_code=401, detail=detail)

    token_data = response.json() if response.content else {}
    access_token = token_data.get("access_token")
    refresh_token = token_data.get("refresh_token")

    if not access_token:
        raise HTTPException(
            status_code=401, detail="Authentication failed: no access token returned"
        )

    user, created = await _ensure_user_from_access_token(access_token, db)

    return CredentialLoginResponse(
        success=True,
        created=created,
        user_id=str(user.id),
        user=user_schema.User.model_validate(user),
        access_token=access_token,
        refresh_token=refresh_token,
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

    async with httpx.AsyncClient() as client:
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
