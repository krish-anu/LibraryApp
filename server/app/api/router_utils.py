from fastapi import HTTPException


def raise_store_http_error(error: Exception) -> None:
    raise HTTPException(status_code=501, detail=str(error)) from error
