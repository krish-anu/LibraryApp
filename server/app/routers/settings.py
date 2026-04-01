import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..dependencies import get_db, verify_access_token
from ..models import settings as settings_model
from ..pydantic_schemas import settings as settings_schema

router = APIRouter(
    prefix="/settings", tags=["settings"], dependencies=[Depends(verify_access_token)]
)


def _get_or_create_settings_row(db: Session) -> settings_model.Settings:
    row = (
        db.query(settings_model.Settings)
        .order_by(settings_model.Settings.created_at.asc())
        .first()
    )
    if row:
        return row

    row = settings_model.Settings(id=f'x{__import__("random").randint(100000, 999999)}')
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.get("", response_model=settings_schema.Settings)
def get_settings(db: Session = Depends(get_db)):
    return _get_or_create_settings_row(db)


@router.put("", response_model=settings_schema.Settings)
def update_settings(
    payload: settings_schema.SettingsUpdate,
    db: Session = Depends(get_db),
):
    row = _get_or_create_settings_row(db)
    updates = payload.model_dump(exclude_unset=True)

    for key, value in updates.items():
        setattr(row, key, value)

    db.commit()
    db.refresh(row)
    return row
