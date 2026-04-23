from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from ..dependencies import get_store, verify_access_token
from ..firestore_store import LibraryStore
from ..pydantic_schemas import loan as loan_schema
from ..router_utils import raise_store_http_error


router = APIRouter(
    prefix="/loans", tags=["loans"], dependencies=[Depends(verify_access_token)]
)


class BorrowRequest(BaseModel):
    book_id: str | None = Field(default=None, alias="bookId")
    member_id: str | None = Field(default=None, alias="memberId")

    model_config = ConfigDict(populate_by_name=True)


@router.get("", response_model=List[loan_schema.Loan])
def get_loans(store: LibraryStore = Depends(get_store)):
    try:
        return store.list_loans()
    except Exception as error:
        raise_store_http_error(error)


@router.get("/active", response_model=List[loan_schema.Loan])
def get_active_loans(
    member_id: Optional[str] = None,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.list_active_loans(member_id)
    except Exception as error:
        raise_store_http_error(error)


@router.post("", response_model=loan_schema.Loan, status_code=201)
def borrow_book_from_body(
    payload: BorrowRequest,
    store: LibraryStore = Depends(get_store),
    current_user: dict = Depends(verify_access_token),
):
    resolved_member_id = payload.member_id or current_user.get("sub")
    try:
        if not payload.book_id or not resolved_member_id:
            raise HTTPException(status_code=400, detail="book_id and member_id are required")
        return store.borrow_book(payload.book_id, resolved_member_id)
    except HTTPException:
        raise
    except Exception as error:
        raise_store_http_error(error)


@router.post("/borrow", response_model=loan_schema.Loan)
def borrow_book(
    book_id: str,
    member_id: str,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.borrow_book(book_id, member_id)
    except Exception as error:
        raise_store_http_error(error)


@router.post("/return/{loan_id}")
@router.post("/{loan_id}/return")
def return_book(loan_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.return_book(loan_id)
    except Exception as error:
        raise_store_http_error(error)


@router.post("/renew/{loan_id}", response_model=loan_schema.Loan)
def renew_loan(loan_id: str, store: LibraryStore = Depends(get_store)):
    try:
        return store.renew_loan(loan_id)
    except Exception as error:
        raise_store_http_error(error)
