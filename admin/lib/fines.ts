import { query } from "@/lib/db";

let fineInfraReady = false;

async function getTableColumnSet(tableName: string): Promise<Set<string>> {
  const rows = await query<{ column_name: string }>(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = $1`,
    [tableName],
  );
  return new Set(rows.map((r) => r.column_name));
}

export async function ensureFineInfrastructure(): Promise<void> {
  if (fineInfraReady) return;

  await query(
    `ALTER TABLE fines
     ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'unpaid'`,
  );
  await query(`ALTER TABLE fines ADD COLUMN IF NOT EXISTS member_id TEXT`);
  await query(`ALTER TABLE fines ADD COLUMN IF NOT EXISTS fine_amount NUMERIC`);
  await query(`ALTER TABLE fines ADD COLUMN IF NOT EXISTS fine_date DATE`);
  await query(`ALTER TABLE fines ADD COLUMN IF NOT EXISTS reason TEXT`);
  await query(`ALTER TABLE fines ADD COLUMN IF NOT EXISTS due_date DATE`);
  await query(`ALTER TABLE fines ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP`);
  await query(
    `ALTER TABLE fines ADD COLUMN IF NOT EXISTS payment_method TEXT`,
  );
  await query(
    `ALTER TABLE fines ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()`,
  );
  await query(
    `ALTER TABLE fines ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()`,
  );
  await query(
    `UPDATE fines
     SET status = 'unpaid'
     WHERE status IS NULL OR TRIM(status) = ''`,
  );
  await query(
    `DO $$
     BEGIN
       IF EXISTS (
         SELECT 1
         FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'fines'
           AND column_name = 'user_id'
       ) THEN
         UPDATE fines
         SET member_id = COALESCE(member_id, user_id::text)
         WHERE member_id IS NULL OR TRIM(member_id) = '';
       END IF;

       IF EXISTS (
         SELECT 1
         FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'fines'
           AND column_name = 'amount'
       ) THEN
         UPDATE fines
         SET fine_amount = COALESCE(fine_amount, amount)
         WHERE fine_amount IS NULL;
       END IF;

       IF EXISTS (
         SELECT 1
         FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'fines'
           AND column_name = 'created_at'
       ) THEN
         UPDATE fines
         SET fine_date = COALESCE(fine_date, created_at::date, CURRENT_DATE)
         WHERE fine_date IS NULL;
       ELSE
         UPDATE fines
         SET fine_date = COALESCE(fine_date, CURRENT_DATE)
         WHERE fine_date IS NULL;
       END IF;
     END
     $$`,
  );
  await query(
    `UPDATE fines
     SET updated_at = COALESCE(updated_at, created_at, NOW())
     WHERE updated_at IS NULL`,
  );
  await query(
    `UPDATE fines
     SET fine_amount = NULL
     WHERE fine_amount IS NOT NULL
       AND fine_amount::text = 'NaN'`,
  );

  await query(
    `CREATE TABLE IF NOT EXISTS fine_payments (
      id TEXT PRIMARY KEY,
      member_id TEXT REFERENCES users(id),
      payment_date DATE,
      payment_amount NUMERIC
    )`,
  );
  await query(
    `ALTER TABLE fine_payments
     ADD COLUMN IF NOT EXISTS fine_id TEXT REFERENCES fines(id) ON DELETE CASCADE`,
  );
  await query(
    `ALTER TABLE fine_payments
     ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'physical'`,
  );
  await query(
    `ALTER TABLE fine_payments
     ADD COLUMN IF NOT EXISTS handled_by TEXT`,
  );
  await query(`ALTER TABLE fine_payments ADD COLUMN IF NOT EXISTS notes TEXT`);
  await query(
    `ALTER TABLE fine_payments
     ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()`,
  );
  await query(
    `UPDATE fine_payments
     SET payment_method = 'physical'
     WHERE payment_method IS NULL OR TRIM(payment_method) = ''`,
  );
  await query(
    `CREATE INDEX IF NOT EXISTS idx_fines_status ON fines(status)`,
  );
  await query(
    `CREATE INDEX IF NOT EXISTS idx_fine_payments_fine_id ON fine_payments(fine_id)`,
  );

  fineInfraReady = true;
}

export async function syncOverdueLoanFines(): Promise<void> {
  await ensureFineInfrastructure();

  const loanColumns = await getTableColumnSet("loans");
  const dueCandidates = ["returned_date", "due_date", "return_date"].filter((c) =>
    loanColumns.has(c),
  );
  let dueColumn: string | null = null;
  let fallbackDueColumn: string | null = null;
  let bestOverdueCount = -1;
  for (const candidate of dueCandidates) {
    const row = await query<{
      non_null_count: number;
      overdue_count: number;
    }>(
      `SELECT
         COUNT(*) FILTER (WHERE ${candidate} IS NOT NULL)::int AS non_null_count,
         COUNT(*) FILTER (
           WHERE ${candidate} IS NOT NULL AND ${candidate}::date < CURRENT_DATE
         )::int AS overdue_count
       FROM loans
      `,
    );
    const nonNullCount = Number(row[0]?.non_null_count || 0);
    const overdueCount = Number(row[0]?.overdue_count || 0);

    if (!fallbackDueColumn && nonNullCount > 0) {
      fallbackDueColumn = candidate;
    }
    if (overdueCount > bestOverdueCount) {
      bestOverdueCount = overdueCount;
      dueColumn = candidate;
    }
  }
  if (bestOverdueCount <= 0) {
    dueColumn = fallbackDueColumn;
  }
  if (!dueColumn && dueCandidates.length) {
    dueColumn = dueCandidates[0];
  }
  const memberColumn = loanColumns.has("member_id")
    ? "member_id"
    : loanColumns.has("user_id")
      ? "user_id"
      : null;

  if (!dueColumn || !memberColumn) {
    return;
  }

  let dailyFineRate = 0.5;
  let maxFineCap = 25;
  try {
    const settings = await query<{
      daily_fine_rate: number;
      max_fine_cap: number;
    }>(
      `SELECT
        COALESCE(daily_fine_rate, 0.5)::float8 AS daily_fine_rate,
        COALESCE(max_fine_cap, 25)::float8 AS max_fine_cap
       FROM settings
       ORDER BY created_at ASC
       LIMIT 1`,
    );
    if (settings[0]) {
      const parsedDailyFineRate = Number(settings[0].daily_fine_rate);
      const parsedMaxFineCap = Number(settings[0].max_fine_cap);
      dailyFineRate =
        Number.isFinite(parsedDailyFineRate) && parsedDailyFineRate > 0
          ? parsedDailyFineRate
          : 0.5;
      maxFineCap =
        Number.isFinite(parsedMaxFineCap) && parsedMaxFineCap > 0
          ? parsedMaxFineCap
          : 25;
    }
  } catch {
    // Use defaults when settings are unavailable.
  }
  maxFineCap = Math.max(maxFineCap, dailyFineRate);

  const overdueLoans = await query<{
    loan_id: string;
    member_id: string;
    due_date: string;
    overdue_days: number;
  }>(
    `SELECT
      CAST(l.id AS TEXT) AS loan_id,
      CAST(l.${memberColumn} AS TEXT) AS member_id,
      l.${dueColumn}::date AS due_date,
      GREATEST(1, CURRENT_DATE - l.${dueColumn}::date)::int AS overdue_days
     FROM loans l
     WHERE l.${memberColumn} IS NOT NULL
       AND l.${dueColumn} IS NOT NULL
       AND l.${dueColumn}::date < CURRENT_DATE`,
  );

  for (const loan of overdueLoans) {
    if (!loan.member_id) continue;

    const overdueDaysRaw = Number(loan.overdue_days);
    const overdueDays =
      Number.isFinite(overdueDaysRaw) && overdueDaysRaw > 0 ? overdueDaysRaw : 1;
    const computedAmount = Math.min(overdueDays * dailyFineRate, maxFineCap);
    if (!Number.isFinite(computedAmount) || computedAmount <= 0) continue;
    const amount = Number(computedAmount.toFixed(2));
    if (!Number.isFinite(amount) || amount <= 0) continue;

    const cyclePaid = await query<{ total_paid: number }>(
      `SELECT
         COALESCE(SUM(fp.payment_amount), 0)::float8 AS total_paid
       FROM fine_payments fp
       JOIN fines f ON f.id = fp.fine_id
       WHERE f.loan_id = $1
         AND f.due_date::date = $2::date`,
      [loan.loan_id, loan.due_date],
    );
    const cyclePaidRaw = Number(cyclePaid[0]?.total_paid);
    const totalPaid =
      Number.isFinite(cyclePaidRaw) && cyclePaidRaw > 0 ? cyclePaidRaw : 0;

    const remainingAmount = Math.max(0, Number((amount - totalPaid).toFixed(2)));
    if (!Number.isFinite(remainingAmount)) continue;
    const nextStatus = remainingAmount <= 0.00001 ? "paid" : "unpaid";

    const unpaidFine = await query<{ id: string }>(
      `SELECT id
       FROM fines
       WHERE loan_id = $1
         AND due_date::date = $2::date
         AND LOWER(COALESCE(status, 'unpaid')) = 'unpaid'
       ORDER BY COALESCE(updated_at, created_at, NOW()) DESC
       LIMIT 1`,
      [loan.loan_id, loan.due_date],
    );

    if (unpaidFine.length) {
      await query(
        `UPDATE fines
         SET
           member_id = COALESCE(member_id, $1),
           fine_amount = $2,
           fine_date = COALESCE(fine_date, CURRENT_DATE),
           reason = COALESCE(reason, 'Overdue return'),
           due_date = COALESCE(due_date, $3::date),
           status = $4,
           paid_at = CASE
             WHEN $4 = 'paid' THEN COALESCE(paid_at, NOW())
             ELSE NULL
           END,
           payment_method = CASE
             WHEN $4 = 'paid' THEN COALESCE(payment_method, 'physical')
             ELSE payment_method
           END,
           updated_at = NOW()
         WHERE id = $5`,
        [loan.member_id, remainingAmount, loan.due_date, nextStatus, unpaidFine[0].id],
      );
      continue;
    }

    if (remainingAmount > 0.00001) {
      await query(
        `INSERT INTO fines (
          id,
          member_id,
          loan_id,
          fine_date,
          fine_amount,
          status,
          reason,
          due_date,
          created_at,
          updated_at
        ) VALUES (
          $1, $2, $3, CURRENT_DATE, $4, 'unpaid',
          'Overdue return', $5, NOW(), NOW()
        )`,
        [
          crypto.randomUUID(),
          loan.member_id,
          loan.loan_id,
          remainingAmount,
          loan.due_date,
        ],
      );
    }
  }

  // Repair legacy/invalid rows where overdue unpaid fines are stuck at 0/NaN.
  const invalidUnpaidFines = await query<{
    id: string;
    due_date: string;
    overdue_days: number;
    total_paid: number;
  }>(
    `SELECT
       f.id,
       f.due_date::date AS due_date,
       GREATEST(1, CURRENT_DATE - f.due_date::date)::int AS overdue_days,
       COALESCE((
         SELECT SUM(fp.payment_amount)
         FROM fine_payments fp
         WHERE fp.fine_id = f.id
       ), 0)::float8 AS total_paid
     FROM fines f
     JOIN loans l ON CAST(l.id AS TEXT) = CAST(f.loan_id AS TEXT)
     WHERE LOWER(COALESCE(f.status, 'unpaid')) = 'unpaid'
       AND f.due_date IS NOT NULL
       AND l.${dueColumn} IS NOT NULL
       AND l.${dueColumn}::date = f.due_date::date
       AND f.due_date::date < CURRENT_DATE
       AND (
         f.fine_amount IS NULL
         OR f.fine_amount::text = 'NaN'
         OR COALESCE(f.fine_amount, 0) <= 0
       )`,
  );

  for (const fine of invalidUnpaidFines) {
    const overdueDaysRaw = Number(fine.overdue_days);
    const overdueDays =
      Number.isFinite(overdueDaysRaw) && overdueDaysRaw > 0 ? overdueDaysRaw : 1;
    const computedAmount = Math.min(overdueDays * dailyFineRate, maxFineCap);
    if (!Number.isFinite(computedAmount) || computedAmount <= 0) continue;

    const totalPaidRaw = Number(fine.total_paid);
    const totalPaid =
      Number.isFinite(totalPaidRaw) && totalPaidRaw > 0 ? totalPaidRaw : 0;
    const remainingAmount = Math.max(0, Number(computedAmount.toFixed(2)) - totalPaid);
    if (!Number.isFinite(remainingAmount)) continue;

    const nextStatus = remainingAmount <= 0.00001 ? "paid" : "unpaid";
    await query(
      `UPDATE fines
       SET
         fine_amount = $1,
         status = $2,
         paid_at = CASE
           WHEN $2 = 'paid' THEN COALESCE(paid_at, NOW())
           ELSE NULL
         END,
         payment_method = CASE
           WHEN $2 = 'paid' THEN COALESCE(payment_method, 'physical')
           ELSE payment_method
         END,
         updated_at = NOW()
       WHERE id = $3`,
      [remainingAmount, nextStatus, fine.id],
    );
  }
}
