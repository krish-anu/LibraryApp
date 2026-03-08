import { NextRequest, NextResponse } from "next/server";
import { getClient, query } from "@/lib/db";
import { ensureFineInfrastructure } from "@/lib/fines";
import { verifyAdmin } from "@/lib/auth/verify-admin";

const ADMIN_RENEWAL_DAYS = 14;
const LOAN_DUE_COLUMN_CANDIDATES = [
  "returned_date",
  "due_date",
  "return_date",
] as const;
const LOAN_MEMBER_COLUMN_CANDIDATES = ["member_id", "user_id"] as const;
const SQL_IDENTIFIER = /^[a-z_][a-z0-9_]*$/;

type LoanDueColumn = (typeof LOAN_DUE_COLUMN_CANDIDATES)[number];
type LoanMemberColumn = (typeof LOAN_MEMBER_COLUMN_CANDIDATES)[number];

async function getLoanColumnSet(): Promise<Set<string>> {
  const rows = await query<{ column_name: string }>(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'loans'`,
  );
  return new Set(rows.map((row) => row.column_name));
}

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

function pickLoanColumns(columns: Set<string>): {
  dueColumn: LoanDueColumn | null;
  memberColumn: LoanMemberColumn | null;
} {
  const dueColumn = pickAllowedColumn(columns, LOAN_DUE_COLUMN_CANDIDATES);
  const memberColumn = pickAllowedColumn(
    columns,
    LOAN_MEMBER_COLUMN_CANDIDATES,
  );

  return { dueColumn, memberColumn };
}

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(_request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    await ensureFineInfrastructure();

    const loanColumns = await getLoanColumnSet();
    const { dueColumn, memberColumn } = pickLoanColumns(loanColumns);
    if (!dueColumn) {
      return NextResponse.json(
        { error: "Loan due-date column is not available" },
        { status: 500 },
      );
    }
    const safeDueColumn = assertSafeIdentifier(
      dueColumn,
      LOAN_DUE_COLUMN_CANDIDATES,
    );
    const safeMemberColumn = memberColumn
      ? assertSafeIdentifier(memberColumn, LOAN_MEMBER_COLUMN_CANDIDATES)
      : null;

    const client = await getClient();
    try {
      await client.query("BEGIN");

      const loanResult = await client.query<{
        id: string;
        member_id: string | null;
        due_date: string | null;
      }>(
        `SELECT
           id,
           ${
             safeMemberColumn ? `CAST(${safeMemberColumn} AS TEXT)` : "NULL"
           } AS member_id,
           ${safeDueColumn}::date AS due_date
         FROM loans
         WHERE id = $1
         FOR UPDATE`,
        [id],
      );

      if (!loanResult.rows.length) {
        await client.query("ROLLBACK");
        return NextResponse.json({ error: "Loan not found" }, { status: 404 });
      }

      const loan = loanResult.rows[0];
      const dueDate = loan.due_date;
      const memberId = loan.member_id;

      let lateFineCreatedOrUpdated = false;
      if (dueDate && memberId) {
        const overdueDaysResult = await client.query<{ overdue_days: number }>(
          `SELECT GREATEST(0, CURRENT_DATE - $1::date)::int AS overdue_days`,
          [dueDate],
        );
        const overdueDays = Number(
          overdueDaysResult.rows[0]?.overdue_days || 0,
        );

        if (overdueDays > 0) {
          const settings = await client.query<{
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
          const parsedRate = Number(settings.rows[0]?.daily_fine_rate);
          const parsedCap = Number(settings.rows[0]?.max_fine_cap);
          const dailyFineRate =
            Number.isFinite(parsedRate) && parsedRate > 0 ? parsedRate : 0.5;
          const maxFineCap =
            Number.isFinite(parsedCap) && parsedCap > 0 ? parsedCap : 25;

          const cyclePaidResult = await client.query<{ total_paid: number }>(
            `SELECT
               COALESCE(SUM(fp.payment_amount), 0)::float8 AS total_paid
             FROM fine_payments fp
             JOIN fines f ON f.id = fp.fine_id
             WHERE f.loan_id = $1
               AND f.due_date::date = $2::date`,
            [id, dueDate],
          );
          const cyclePaidRaw = Number(cyclePaidResult.rows[0]?.total_paid || 0);
          const cyclePaid =
            Number.isFinite(cyclePaidRaw) && cyclePaidRaw > 0
              ? cyclePaidRaw
              : 0;

          const computedAmount = Math.min(
            overdueDays * dailyFineRate,
            Math.max(maxFineCap, dailyFineRate),
          );
          const remainingAmount = Math.max(
            0,
            Number(computedAmount.toFixed(2)) - cyclePaid,
          );

          if (Number.isFinite(remainingAmount) && remainingAmount > 0.00001) {
            const unpaidFineResult = await client.query<{ id: string }>(
              `SELECT id
               FROM fines
               WHERE loan_id = $1
                 AND due_date::date = $2::date
                 AND LOWER(COALESCE(status, 'unpaid')) = 'unpaid'
               ORDER BY COALESCE(updated_at, created_at, NOW()) DESC
               LIMIT 1`,
              [id, dueDate],
            );

            if (unpaidFineResult.rows.length) {
              await client.query(
                `UPDATE fines
                 SET
                   member_id = COALESCE(member_id, $1),
                   fine_amount = $2,
                   fine_date = COALESCE(fine_date, CURRENT_DATE),
                   reason = COALESCE(reason, 'Overdue return'),
                   due_date = COALESCE(due_date, $3::date),
                   status = 'unpaid',
                   paid_at = NULL,
                   updated_at = NOW()
                 WHERE id = $4`,
                [
                  memberId,
                  remainingAmount,
                  dueDate,
                  unpaidFineResult.rows[0].id,
                ],
              );
            } else {
              await client.query(
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
                [crypto.randomUUID(), memberId, id, remainingAmount, dueDate],
              );
            }
            lateFineCreatedOrUpdated = true;
          }
        }
      }

      const updatedLoanResult = await client.query(
        `UPDATE loans
         SET ${safeDueColumn} = (
           CASE
             WHEN ${safeDueColumn} IS NOT NULL AND ${safeDueColumn}::date > CURRENT_DATE
               THEN ${safeDueColumn}::date
             ELSE CURRENT_DATE
           END
         ) + $1::int
         WHERE id = $2
         RETURNING *`,
        [ADMIN_RENEWAL_DAYS, id],
      );

      await client.query("COMMIT");

      return NextResponse.json({
        data: updatedLoanResult.rows[0],
        message: lateFineCreatedOrUpdated
          ? `Loan renewed by admin for ${ADMIN_RENEWAL_DAYS} days. Late renewal fine updated for overdue days before renewal.`
          : `Loan renewed by admin for ${ADMIN_RENEWAL_DAYS} days.`,
      });
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error("Error renewing loan:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
