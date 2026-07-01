from pathlib import Path
import sys

SERVER_ROOT = Path(__file__).resolve().parents[2]
if str(SERVER_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVER_ROOT))

from app.database import engine


MIGRATION_STATEMENTS = [
    "DROP TABLE IF EXISTS book_author CASCADE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image TEXT",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS joined_date DATE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP",
    "UPDATE users SET created_at = NOW() WHERE created_at IS NULL",
    "UPDATE users SET updated_at = NOW() WHERE updated_at IS NULL",
    "ALTER TABLE users ALTER COLUMN created_at SET DEFAULT NOW()",
    "ALTER TABLE users ALTER COLUMN updated_at SET DEFAULT NOW()",
    "ALTER TABLE fines ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'unpaid'",
    "ALTER TABLE fines ADD COLUMN IF NOT EXISTS reason TEXT",
    "ALTER TABLE fines ADD COLUMN IF NOT EXISTS due_date DATE",
    "ALTER TABLE fines ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP",
    "ALTER TABLE fines ADD COLUMN IF NOT EXISTS payment_method TEXT",
    "ALTER TABLE fines ADD COLUMN IF NOT EXISTS created_at TIMESTAMP",
    "ALTER TABLE fines ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP",
    "UPDATE fines SET status = 'unpaid' WHERE status IS NULL OR TRIM(status) = ''",
    "ALTER TABLE loans ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active'",
    "ALTER TABLE loans ADD COLUMN IF NOT EXISTS returned_at DATE",
    "ALTER TABLE loans ADD COLUMN IF NOT EXISTS returned_by TEXT",
    "UPDATE loans SET status = 'active' WHERE status IS NULL OR TRIM(status) = ''",
    """
    CREATE TABLE IF NOT EXISTS fine_payments (
        id TEXT PRIMARY KEY,
        member_id TEXT REFERENCES users(id),
        payment_date DATE,
        payment_amount NUMERIC
    )
    """,
    "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS fine_id TEXT REFERENCES fines(id) ON DELETE CASCADE",
    "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'physical'",
    "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS handled_by TEXT",
    "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS notes TEXT",
    "ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS created_at TIMESTAMP",
    "UPDATE fine_payments SET payment_method = 'physical' WHERE payment_method IS NULL OR TRIM(payment_method) = ''",
    """
    INSERT INTO settings (
        id,
        loan_period_days,
        max_books_per_user,
        grace_period_days,
        daily_fine_rate,
        max_fine_cap,
        block_on_unpaid_fines,
        fine_threshold,
        send_notifications,
        notification_days_before_due,
        created_at,
        updated_at
    )
    SELECT
        '00000000-0000-0000-0000-000000000001',
        14,
        5,
        2,
        0.50,
        25.00,
        true,
        10.00,
        true,
        3,
        NOW(),
        NOW()
    WHERE NOT EXISTS (SELECT 1 FROM settings)
    """,
    # Null out orphan references before adding FK constraints.
    """
    UPDATE reservations r
    SET book_id = NULL
    WHERE book_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM books b WHERE b.id = r.book_id)
    """,
    """
    UPDATE reservations r
    SET member_id = NULL
    WHERE member_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = r.member_id)
    """,
    """
    UPDATE fines f
    SET member_id = NULL
    WHERE member_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = f.member_id)
    """,
    """
    UPDATE fines f
    SET loan_id = NULL
    WHERE loan_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM loans l WHERE l.id = f.loan_id)
    """,
    """
    UPDATE fine_payments fp
    SET member_id = NULL
    WHERE member_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = fp.member_id)
    """,
    # Add missing foreign keys only if absent.
    """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conname = 'reservations_book_id_fkey'
        ) THEN
            ALTER TABLE reservations
            ADD CONSTRAINT reservations_book_id_fkey
            FOREIGN KEY (book_id) REFERENCES books(id);
        END IF;
    END
    $$;
    """,
    """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conname = 'reservations_member_id_fkey'
        ) THEN
            ALTER TABLE reservations
            ADD CONSTRAINT reservations_member_id_fkey
            FOREIGN KEY (member_id) REFERENCES users(id);
        END IF;
    END
    $$;
    """,
    """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conname = 'fines_member_id_fkey'
        ) THEN
            ALTER TABLE fines
            ADD CONSTRAINT fines_member_id_fkey
            FOREIGN KEY (member_id) REFERENCES users(id);
        END IF;
    END
    $$;
    """,
    """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conname = 'fines_loan_id_fkey'
        ) THEN
            ALTER TABLE fines
            ADD CONSTRAINT fines_loan_id_fkey
            FOREIGN KEY (loan_id) REFERENCES loans(id);
        END IF;
    END
    $$;
    """,
    """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conname = 'fine_payments_member_id_fkey'
        ) THEN
            ALTER TABLE fine_payments
            ADD CONSTRAINT fine_payments_member_id_fkey
            FOREIGN KEY (member_id) REFERENCES users(id);
        END IF;
    END
    $$;
    """,
]


def run() -> None:
    with engine.begin() as conn:
        for statement in MIGRATION_STATEMENTS:
            conn.exec_driver_sql(statement)

    print("startup schema migration applied")


if __name__ == "__main__":
    run()
