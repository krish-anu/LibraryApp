from fastapi import APIRouter, Depends

from app.dependencies import get_store, verify_access_token
from app.firestore_store import LibraryStore
from app.pydantic_schemas import user as user_schema
from app.router_utils import raise_store_http_error


router = APIRouter(
    prefix="/users", tags=["users"], dependencies=[Depends(verify_access_token)]
)


@router.get("/{user_id}", response_model=user_schema.User)
def get_user(user_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.get_user(user_id)
    except Exception as error:
        raise_store_http_error(error)


@router.get("/by-member/{member_id}", response_model=user_schema.User)
def get_user_by_member(member_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.get_user_by_member(member_id)
    except Exception as error:
        raise_store_http_error(error)


@router.put("/{user_id}", response_model=user_schema.User)
def update_user(
    user_id: str,
    user_update: user_schema.UserUpdate,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.update_user(user_id, user_update.model_dump(exclude_unset=True))
    except Exception as error:
        raise_store_http_error(error)


@router.get("/{user_id}/stats", response_model=user_schema.ProfileStats)
def get_user_stats(user_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.get_user_stats(user_id)
    except Exception as error:
        raise_store_http_error(error)
