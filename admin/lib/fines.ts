import { query } from "@/lib/db";

const LOAN_DUE_COLUMN_CANDIDATES = [
  "returned_date",
  "due_date",
  "return_date",
] as const;
const LOAN_MEMBER_COLUMN_CANDIDATES = ["member_id", "user_id"] as const;
const SQL_IDENTIFIER = /^[a-z_][a-z0-9_]*$/;

type LoanDueColumn = (typeof LOAN_DUE_COLUMN_CANDIDATES)[number];

function pickAllowedColumn<T extends readonly string[]>(
  columns: Set<string>,
  candidates: T,
): T[number] | null {
  for (const candidate of candidates) {
    if (columns.has(candidate)) return candidate;
  }
  return null;
}

function assertSafeIdentifier(
  value: string,
  allowlist: readonly string[],
): string {
  if (!SQL_IDENTIFIER.test(value) || !allowlist.includes(value)) {
    throw new Error(`Unsafe SQL identifier: ${value}`);
  }
  return value;
}

async function getTableColumnSet(tableName: string): Promise<Set<string>> {
  const rows = await query<{ column_name: string }>(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = $1`,
    [tableName],
  );
  return new Set(rows.map((r) => r.column_name));
}

let fineInfraPromise: Promise<void> | null = null;

async function _ensureFineInfrastructure(): Promise<void> {
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
  await query(`ALTER TABLE fines ADD COLUMN IF NOT EXISTS payment_method TEXT`);
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
  await query(`CREATE INDEX IF NOT EXISTS idx_fines_status ON fines(status)`);
  await query(
    `CREATE INDEX IF NOT EXISTS idx_fine_payments_fine_id ON fine_payments(fine_id)`,
  );
}

export async function ensureFineInfrastructure(): Promise<void> {
  if (!fineInfraPromise) {
    fineInfraPromise = _ensureFineInfrastructure().catch((err) => {
      fineInfraPromise = null;
      throw err;
    });
  }
  return fineInfraPromise;
}

export async function syncOverdueLoanFines(): Promise<void> {
  await ensureFineInfrastructure();

  const loanColumns = await getTableColumnSet("loans");
  const dueCandidates: LoanDueColumn[] = LOAN_DUE_COLUMN_CANDIDATES.filter(
    (c) => loanColumns.has(c),
  );
  let dueColumn: LoanDueColumn | null = null;
  let fallbackDueColumn: LoanDueColumn | null = null;
  let bestOverdueCount = -1;
  for (const candidate of dueCandidates) {
    const safeCandidate = assertSafeIdentifier(
      candidate,
      LOAN_DUE_COLUMN_CANDIDATES,
    );
    const row = await query<{
      non_null_count: number;
      overdue_count: number;
    }>(
      `SELECT
         COUNT(*) FILTER (WHERE ${safeCandidate} IS NOT NULL)::int AS non_null_count,
         COUNT(*) FILTER (
           WHERE ${safeCandidate} IS NOT NULL AND ${safeCandidate}::date < CURRENT_DATE
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
  const memberColumn = pickAllowedColumn(
    loanColumns,
    LOAN_MEMBER_COLUMN_CANDIDATES,
  );

  if (!dueColumn || !memberColumn) {
    return;
  }
  const safeDueColumn = assertSafeIdentifier(
    dueColumn,
    LOAN_DUE_COLUMN_CANDIDATES,
  );
  const safeMemberColumn = assertSafeIdentifier(
    memberColumn,
    LOAN_MEMBER_COLUMN_CANDIDATES,
  );

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
      CAST(l.${safeMemberColumn} AS TEXT) AS member_id,
      l.${safeDueColumn}::date AS due_date,
      GREATEST(1, CURRENT_DATE - l.${safeDueColumn}::date)::int AS overdue_days
     FROM loans l
     WHERE l.${safeMemberColumn} IS NOT NULL
       AND l.${safeDueColumn} IS NOT NULL
       AND l.${safeDueColumn}::date < CURRENT_DATE`,
  );

  if (overdueLoans.length === 0) {
    // skip optimization step if no overdue loans
  } else {
    // Batch fetch total paid for all relevant fines
    const allCyclePaids = await query<{
      loan_id: string;
      due_date: string;
      total_paid: number;
    }>(
      `SELECT
         f.loan_id,
         f.due_date::date AS due_date,
         COALESCE(SUM(fp.payment_amount), 0)::float8 AS total_paid
       FROM fine_payments fp
       JOIN fines f ON f.id = fp.fine_id
       WHERE f.loan_id IS NOT NULL 
         AND f.due_date IS NOT NULL
       GROUP BY f.loan_id, f.due_date::date`,
    );

    const cyclePaidMap = new Map<string, number>();
    for (const row of allCyclePaids) {
      const key = `${row.loan_id}_${row.due_date}`;
      const val = Number(row.total_paid);
      cyclePaidMap.set(key, Number.isFinite(val) && val > 0 ? val : 0);
    }

    // Batch fetch all unpaid fines
    const allUnpaidFines = await query<{
      id: string;
      loan_id: string;
      due_date: string;
    }>(
      `SELECT id, loan_id, due_date::date AS due_date
       FROM fines
       WHERE loan_id IS NOT NULL
         AND due_date IS NOT NULL
         AND LOWER(COALESCE(status, 'unpaid')) = 'unpaid'`,
    );

    const unpaidFineMap = new Map<string, string>();
    for (const row of allUnpaidFines) {
      const key = `${row.loan_id}_${row.due_date}`;
      // Keep the most recently seen if there are duplicates (though query previously used ORDER BY)
      if (!unpaidFineMap.has(key)) {
        unpaidFineMap.set(key, row.id);
      }
    }

    const updates: {
      id: string;
      member_id: string;
      remainingAmount: number;
      due_date: string;
      nextStatus: string;
    }[] = [];
    const inserts: {
      id: string;
      member_id: string;
      loan_id: string;
      remainingAmount: number;
      due_date: string;
    }[] = [];

    for (const loan of overdueLoans) {
      if (!loan.member_id) continue;

      const overdueDaysRaw = Number(loan.overdue_days);
      const overdueDays =
        Number.isFinite(overdueDaysRaw) && overdueDaysRaw > 0
          ? overdueDaysRaw
          : 1;
      const computedAmount = Math.min(overdueDays * dailyFineRate, maxFineCap);
      if (!Number.isFinite(computedAmount) || computedAmount <= 0) continue;
      const amount = Number(computedAmount.toFixed(2));
      if (!Number.isFinite(amount) || amount <= 0) continue;

      const key = `${loan.loan_id}_${loan.due_date}`;
      let totalPaid = cyclePaidMap.get(key) || 0;

      const remainingAmount = Math.max(
        0,
        Number((amount - totalPaid).toFixed(2)),
      );
      if (!Number.isFinite(remainingAmount)) continue;
      const nextStatus = remainingAmount <= 0.00001 ? "paid" : "unpaid";

      const unpaidFineId = unpaidFineMap.get(key);

      if (unpaidFineId) {
        updates.push({
          id: unpaidFineId,
          member_id: loan.member_id,
          remainingAmount,
          due_date: loan.due_date,
          nextStatus,
        });
        continue;
      }

      if (remainingAmount > 0.00001) {
        inserts.push({
          id: crypto.randomUUID(),
          member_id: loan.member_id,
          loan_id: loan.loan_id,
          remainingAmount,
          due_date: loan.due_date,
        });
      }
    }

    for (const u of updates) {
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
        [u.member_id, u.remainingAmount, u.due_date, u.nextStatus, u.id],
      );
    }

    for (const ins of inserts) {
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
        [ins.id, ins.member_id, ins.loan_id, ins.remainingAmount, ins.due_date],
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
       AND l.${safeDueColumn} IS NOT NULL
       AND l.${safeDueColumn}::date = f.due_date::date
       AND f.due_date::date < CURRENT_DATE
       AND (
         f.fine_amount IS NULL
         OR f.fine_amount::text = 'NaN'
         OR COALESCE(f.fine_amount, 0) <= 0
       )`,
  );

  const repairUpdates: {
    id: string;
    remainingAmount: number;
    nextStatus: string;
  }[] = [];
  for (const fine of invalidUnpaidFines) {
    const overdueDaysRaw = Number(fine.overdue_days);
    const overdueDays =
      Number.isFinite(overdueDaysRaw) && overdueDaysRaw > 0
        ? overdueDaysRaw
        : 1;
    const computedAmount = Math.min(overdueDays * dailyFineRate, maxFineCap);
    if (!Number.isFinite(computedAmount) || computedAmount <= 0) continue;

    const totalPaidRaw = Number(fine.total_paid);
    const totalPaid =
      Number.isFinite(totalPaidRaw) && totalPaidRaw > 0 ? totalPaidRaw : 0;
    const remainingAmount = Math.max(
      0,
      Number(computedAmount.toFixed(2)) - totalPaid,
    );
    if (!Number.isFinite(remainingAmount)) continue;

    const nextStatus = remainingAmount <= 0.00001 ? "paid" : "unpaid";
    repairUpdates.push({
      id: fine.id,
      remainingAmount,
      nextStatus,
    });
  }

  for (const u of repairUpdates) {
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
      [u.remainingAmount, u.nextStatus, u.id],
    );
  }
}
