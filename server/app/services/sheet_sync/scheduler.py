from __future__ import annotations

import asyncio
from datetime import datetime, timedelta

from app.db import SessionLocal
from app.models.settings import Settings
from app.routers.settings import _get_or_create_settings_row
from .service import run_sheet_sync


class SheetSyncScheduler:
    def __init__(self) -> None:
        self._task: asyncio.Task | None = None
        self._running = False

    async def start(self) -> None:
        if self._task:
            return
        self._task = asyncio.create_task(self._loop())

    async def stop(self) -> None:
        task = self._task
        self._task = None
        if not task:
            return
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass

    async def _loop(self) -> None:
        while True:
            await asyncio.sleep(3600)
            if self._running:
                continue
            self._running = True
            try:
                await asyncio.to_thread(self._run_if_due)
            finally:
                self._running = False

    def _run_if_due(self) -> None:
        db = SessionLocal()
        try:
            settings = _get_or_create_settings_row(db)
            if not settings.sheet_sync_enabled or not settings.sheet_spreadsheet_id:
                return

            interval = max(1, int(settings.sheet_sync_interval_days or 30))
            last_sync = settings.sheet_last_sync_at
            if last_sync and datetime.utcnow() - last_sync < timedelta(days=interval):
                return

            try:
                run_sheet_sync(db, settings)
            except Exception as exc:
                settings.sheet_last_sync_at = datetime.utcnow()
                settings.sheet_last_sync_status = "failed"
                settings.sheet_last_sync_message = str(exc)
                db.commit()
        finally:
            db.close()


sheet_sync_scheduler = SheetSyncScheduler()
