from fastapi import HTTPException

from .firestore_store import (
    ConfigurationError,
    ConflictError,
    NotFoundError,
    ValidationError,
)


def raise_store_http_error(error: Exception) -> None:
    if isinstance(error, NotFoundError):
        raise HTTPException(status_code=404, detail=str(error)) from error
    if isinstance(error, ConflictError):
        raise HTTPException(status_code=409, detail=str(error)) from error
    if isinstance(error, ValidationError):
        raise HTTPException(status_code=400, detail=str(error)) from error
    if isinstance(error, ConfigurationError):
        raise HTTPException(status_code=503, detail=str(error)) from error
    raise error
