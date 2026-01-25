"""
Asgardeo Authentication Router

This router handles user registration via Asgardeo's SCIM2 API.
For public mobile clients, registration must go through a backend service
that has the necessary credentials to create users.
"""

import os
import httpx
from pathlib import Path
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from typing import Optional
from dotenv import load_dotenv

# Load environment variables from .env file
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
load_dotenv(env_path)

router = APIRouter(prefix="/auth", tags=["auth"])

# Asgardeo Configuration - Read from environment variables
ASGARDEO_BASE_URL = os.getenv(
    "ASGARDEO_BASE_URL", "https://api.eu.asgardeo.io/t/orgd2ib6"
)
# This is your M2M (Machine-to-Machine) application credentials for the backend
ASGARDEO_M2M_CLIENT_ID = os.getenv("ASGARDEO_M2M_CLIENT_ID", "")
ASGARDEO_M2M_CLIENT_SECRET = os.getenv("ASGARDEO_M2M_CLIENT_SECRET", "")


class RegisterRequest(BaseModel):
    """Registration request schema."""

    email: EmailStr
    password: str
    first_name: str
    last_name: str
    username: Optional[str] = None
    phone_number: Optional[str] = None


class RegisterResponse(BaseModel):
    """Registration response schema."""

    success: bool
    message: str
    user_id: Optional[str] = None


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
            print(f"Token request failed: {response.text}")

        if response.status_code == 200:
            data = response.json()
            return data.get("access_token")

        return None


@router.post("/register", response_model=RegisterResponse)
async def register_user(request: RegisterRequest):
    """
    Register a new user via Asgardeo API.

    This endpoint allows mobile clients to register users without
    needing confidential client credentials on the device.
    """

    admin_token = await get_client_credentials_token()

    if not admin_token:
        raise HTTPException(
            status_code=500,
            detail="Server configuration error: M2M credentials not configured or invalid.",
        )

    async with httpx.AsyncClient() as client:
        # Try 1: Asgardeo User Management API
        print("Trying Asgardeo User Management API /api/users/v1...")
        user_mgmt_body = {
            "userName": request.email,
            "password": request.password,
            "name": {
                "givenName": request.first_name,
                "familyName": request.last_name,
            },
            "emails": [request.email],
        }

        if request.phone_number:
            user_mgmt_body["phoneNumbers"] = [request.phone_number]

        response = await client.post(
            f"{ASGARDEO_BASE_URL}/api/users/v1",
            json=user_mgmt_body,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": f"Bearer {admin_token}",
            },
        )

        print(
            f"Response: {response.status_code} - {response.text[:500] if response.text else 'empty'}"
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
        print("Trying SCIM2 /o/scim2/Users...")
        scim_user = {
            "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
            "userName": request.email,
            "password": request.password,
            "name": {
                "givenName": request.first_name,
                "familyName": request.last_name,
            },
            "emails": [{"value": request.email, "primary": True}],
        }

        if request.phone_number:
            scim_user["phoneNumbers"] = [
                {"value": request.phone_number, "type": "mobile"}
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

        print(
            f"Response: {response.status_code} - {response.text[:500] if response.text else 'empty'}"
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
        print("Trying SCIM2 /scim2/Users...")
        response = await client.post(
            f"{ASGARDEO_BASE_URL}/scim2/Users",
            json=scim_user,
            headers={
                "Content-Type": "application/scim+json",
                "Accept": "application/scim+json",
                "Authorization": f"Bearer {admin_token}",
            },
        )

        print(
            f"Response: {response.status_code} - {response.text[:500] if response.text else 'empty'}"
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
