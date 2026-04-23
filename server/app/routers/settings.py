from fastapi import APIRouter, Depends

from ..dependencies import get_store, verify_access_token
from ..firestore_store import LibraryStore
from ..pydantic_schemas import settings as settings_schema
from ..router_utils import raise_store_http_error


router = APIRouter(
    prefix="/settings", tags=["settings"], dependencies=[Depends(verify_access_token)]
)


@router.get("", response_model=settings_schema.Settings)
def get_settings(store: LibraryStore = Depends(get_store)):
    try:
        return store.get_settings()
    except Exception as error:
        raise_store_http_error(error)


@router.put("", response_model=settings_schema.Settings)
@router.patch("", response_model=settings_schema.Settings)
def update_settings(
    payload: settings_schema.SettingsUpdate,
    store: LibraryStore = Depends(get_store),
):
    try:
        return store.update_settings(payload.model_dump(exclude_unset=True))
    except Exception as error:
        raise_store_http_error(error)
