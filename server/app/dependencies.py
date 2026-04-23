import os
from functools import lru_cache
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from fastapi import Header, HTTPException

from .firestore_store import FirestoreLibraryStore, LibraryStore


env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

ASGARDEO_BASE_URL = os.getenv("ASGARDEO_BASE_URL", "")


@lru_cache(maxsize=1)
def _get_cached_store() -> FirestoreLibraryStore:
    return FirestoreLibraryStore()


def get_store() -> LibraryStore:
    return _get_cached_store()


def get_db():
    yield get_store()


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
        raise HTTPException(
            status_code=503,
            detail="Unable to verify token with identity provider",
        ) from exc
