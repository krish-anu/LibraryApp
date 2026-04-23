from fastapi import APIRouter, Depends

from ..dependencies import get_store
from ..firestore_store import LibraryStore
from ..router_utils import raise_store_http_error


router = APIRouter(tags=["general"])


@router.get("/")
def root():
    return {"message": "Hello, FastAPI service is working with Firebase!"}


@router.get("/test-db")
def test_db(store: LibraryStore = Depends(get_store)):
    try:
        return store.ping()
    except Exception as error:
        raise_store_http_error(error)
