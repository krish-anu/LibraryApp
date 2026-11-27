from fastapi import APIRouter, Depends
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.dependencies import get_db, require_admin_scope, require_scope
from ..models import settings as settings_model
from ..pydantic_schemas import settings as settings_schema

router = APIRouter(prefix="/settings", tags=["settings"])
DEFAULT_SETTINGS_ID = "00000000-0000-0000-0000-000000000001"


def _get_or_create_settings_row(db: Session) -> settings_model.Settings:
    row = (
        db.query(settings_model.Settings)
        .order_by(settings_model.Settings.created_at.asc())
        .first()
    )
    if row:
        return row

    row = settings_model.Settings(id=DEFAULT_SETTINGS_ID)
    db.add(row)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = db.get(settings_model.Settings, DEFAULT_SETTINGS_ID)
        if existing is None:
            raise
        return existing
    db.refresh(row)
    return row


@router.get("", response_model=settings_schema.Settings)
def get_settings(
    _identity: dict = Depends(require_scope("settings_read")),
    db: Session = Depends(get_db),
):
    return _get_or_create_settings_row(db)


@router.put("", response_model=settings_schema.Settings)
@router.patch("", response_model=settings_schema.Settings)
def update_settings(
    payload: settings_schema.SettingsUpdate,
    _admin: dict = Depends(require_admin_scope("settings_manage")),
    db: Session = Depends(get_db),
):
    row = _get_or_create_settings_row(db)
    updates = payload.model_dump(exclude_unset=True)

    for key, value in updates.items():
        setattr(row, key, value)

    try:
        db.commit()
    except Exception:
        db.rollback()
        raise
    db.refresh(row)
    return row
