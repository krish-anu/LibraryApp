from typing import List

from fastapi import APIRouter, Depends

from ..dependencies import get_store, verify_access_token
from ..firestore_store import LibraryStore
from ..pydantic_schemas import book as book_schema
from ..router_utils import raise_store_http_error


router = APIRouter(
    prefix="/favorites", tags=["favorites"], dependencies=[Depends(verify_access_token)]
)


@router.get("", response_model=List[book_schema.Book])
def get_my_favorites(
    store: LibraryStore = Depends(get_store),
    current_user: dict = Depends(verify_access_token),
):
    try:
        return store.list_favorites(str(current_user.get("sub", "")))
    except Exception as error:
        raise_store_http_error(error)


@router.get("/ids")
def get_my_favorite_ids(
    store: LibraryStore = Depends(get_store),
    current_user: dict = Depends(verify_access_token),
):
    try:
        return store.get_favorite_ids(str(current_user.get("sub", "")))
    except Exception as error:
        raise_store_http_error(error)


@router.post("/me/{book_id}")
def add_my_favorite(
    book_id: str,
    store: LibraryStore = Depends(get_store),
    current_user: dict = Depends(verify_access_token),
):
    try:
        return store.add_favorite(str(current_user.get("sub", "")), book_id)
    except Exception as error:
        raise_store_http_error(error)


@router.delete("/me/{book_id}")
def remove_my_favorite(
    book_id: str,
    store: LibraryStore = Depends(get_store),
    current_user: dict = Depends(verify_access_token),
):
    try:
        return store.remove_favorite(str(current_user.get("sub", "")), book_id)
    except Exception as error:
        raise_store_http_error(error)


@router.get("/me/{book_id}/check")
def check_my_favorite(
    book_id: str,
    store: LibraryStore = Depends(get_store),
    current_user: dict = Depends(verify_access_token),
):
    try:
        return store.check_favorite(str(current_user.get("sub", "")), book_id)
    except Exception as error:
        raise_store_http_error(error)


@router.get("/{member_id}/ids")
def get_favorite_ids(member_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.get_favorite_ids(member_id)
    except Exception as error:
        raise_store_http_error(error)


@router.post("/{member_id}/{book_id}")
def add_favorite(
    member_id: str,
    book_id: str,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.add_favorite(member_id, book_id)
    except Exception as error:
        raise_store_http_error(error)


@router.delete("/{member_id}/{book_id}")
def remove_favorite(
    member_id: str,
    book_id: str,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.remove_favorite(member_id, book_id)
    except Exception as error:
        raise_store_http_error(error)


@router.get("/{member_id}/{book_id}/check")
def check_favorite(
    member_id: str,
    book_id: str,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.check_favorite(member_id, book_id)
    except Exception as error:
        raise_store_http_error(error)


@router.get("/{member_id}", response_model=List[book_schema.Book])
def get_favorites(member_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.list_favorites(member_id)
    except Exception as error:
        raise_store_http_error(error)
