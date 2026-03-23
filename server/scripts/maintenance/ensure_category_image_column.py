from pathlib import Path
import sys

SERVER_ROOT = Path(__file__).resolve().parents[2]
if str(SERVER_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVER_ROOT))

from app.database import engine

with engine.connect() as conn:
    # Check if column exists
    res = conn.exec_driver_sql(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'categories' AND column_name = 'image_url'
        """
    )
    exists = res.first() is not None

    if exists:
        print("column image_url already exists on categories")
    else:
        print("adding column image_url to categories")
        conn.exec_driver_sql("ALTER TABLE categories ADD COLUMN image_url TEXT")
        print("column added")

    conn.commit()

print("done")
