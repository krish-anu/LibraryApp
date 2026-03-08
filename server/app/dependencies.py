import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import Depends, HTTPException, Header
from typing import Optional

from .database import SessionLocal

# Load environment variables
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

ASGARDEO_BASE_URL = os.getenv("ASGARDEO_BASE_URL", "")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def verify_access_token(
    authorization: Optional[str] = Header(default=None),
) -> dict:
    """Verify the Asgardeo access token from the Authorization header.

    Returns the decoded user info if the token is valid.
    Raises HTTPException(401) if the token is missing or invalid.
    """
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Missing Authorization header",
        )

    # Extract Bearer token
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

    # Validate via Asgardeo's userinfo endpoint
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
    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Unable to verify token with identity provider",
        )
