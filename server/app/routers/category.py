from fastapi import APIRouter, Depends
from pydantic import BaseModel

from ..dependencies import get_store, verify_access_token
from ..firestore_store import LibraryStore
from ..router_utils import raise_store_http_error


router = APIRouter(
    prefix="/categories",
    tags=["categories"],
    dependencies=[Depends(verify_access_token)],
)


class CategoryCreate(BaseModel):
    name: str
    image_url: str = ""


@router.get("")
def get_categories(store: LibraryStore = Depends(get_store)):
    try:
        return store.list_categories()
    except Exception as error:
        raise_store_http_error(error)


@router.post("", status_code=201)
def create_category(
    data: CategoryCreate,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.create_category(data.model_dump())
    except Exception as error:
        raise_store_http_error(error)


@router.get("/{category_id}")
def get_category(category_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.get_category(category_id)
    except Exception as error:
        raise_store_http_error(error)


@router.put("/{category_id}")
def update_category(
    category_id: str,
    data: CategoryCreate,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.update_category(category_id, data.model_dump(exclude_unset=True))
    except Exception as error:
        raise_store_http_error(error)


@router.delete("/{category_id}", status_code=204)
def delete_category(category_id: str, store: LibraryStore = Depends(get_store)):
    try:
        store.delete_category(category_id)
        return None
    except Exception as error:
        raise_store_http_error(error)
