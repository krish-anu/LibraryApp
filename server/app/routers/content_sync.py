from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.dependencies import get_db, require_admin_scope
from app.routers.settings import _get_or_create_settings_row
from app.services.sheet_sync import run_sheet_sync

router = APIRouter(prefix="/content-sync", tags=["content-sync"])


class ContentSyncResponse(BaseModel):
    status: str
    message: str
    result: dict[str, int] | None = None


@router.post("/run", response_model=ContentSyncResponse)
def run_content_sync(
    _admin: dict = Depends(require_admin_scope("settings_manage")),
    db: Session = Depends(get_db),
):
    settings = _get_or_create_settings_row(db)
    try:
        result = run_sheet_sync(db, settings)
        return ContentSyncResponse(
            status="success",
            message=f"Synced {result.total} rows",
            result=result.as_dict(),
        )
    except Exception as exc:
        settings.sheet_last_sync_at = datetime.utcnow()
        settings.sheet_last_sync_status = "failed"
        settings.sheet_last_sync_message = str(exc)
        db.commit()
        raise HTTPException(status_code=400, detail=str(exc)) from exc
