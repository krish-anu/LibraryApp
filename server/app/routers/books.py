from typing import List

from fastapi import APIRouter, Depends

from ..dependencies import get_store, verify_access_token
from ..firestore_store import LibraryStore
from ..pydantic_schemas import book as book_schema
from ..router_utils import raise_store_http_error


router = APIRouter(
    prefix="/books", tags=["books"], dependencies=[Depends(verify_access_token)]
)


@router.get("", response_model=List[book_schema.Book])
def get_books(store: LibraryStore = Depends(get_store)):
    try:
        return store.list_books()
    except Exception as error:
        raise_store_http_error(error)


@router.post("", response_model=book_schema.Book, status_code=201)
def create_book(
    book_data: book_schema.BookCreate,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.create_book(book_data.model_dump())
    except Exception as error:
        raise_store_http_error(error)


@router.get("/trending", response_model=List[book_schema.Book])
def get_trending_books(store: LibraryStore = Depends(get_store)):
    try:
        return store.get_trending_books()
    except Exception as error:
        raise_store_http_error(error)


@router.get("/recommended/{user_id}", response_model=List[book_schema.Book])
def get_recommended_books(user_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.get_recommended_books(user_id)
    except Exception as error:
        raise_store_http_error(error)


@router.get("/{book_id}", response_model=book_schema.Book)
def get_book(book_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.get_book(book_id)
    except Exception as error:
        raise_store_http_error(error)


@router.put("/{book_id}", response_model=book_schema.Book)
def update_book(
    book_id: str,
    book_data: book_schema.BookCreate,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.update_book(book_id, book_data.model_dump())
    except Exception as error:
        raise_store_http_error(error)


@router.delete("/{book_id}", status_code=204)
def delete_book(book_id: str, store: LibraryStore = Depends(get_store)):
    try:
        store.delete_book(book_id)
        return None
    except Exception as error:
        raise_store_http_error(error)
