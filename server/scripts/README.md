# Server Scripts

This folder is organized by script purpose:

- `migrations/`: idempotent schema/data migrations for database updates.
- `maintenance/`: one-off maintenance or repair scripts.
- `sql/`: SQL files for policy or manual DB administration tasks.

## Common Commands

Run startup schema migration:

```bash
python scripts/migrations/migrate_startup_schema.py
```

Run category image column maintenance script:

```bash
python scripts/maintenance/ensure_category_image_column.py
```
