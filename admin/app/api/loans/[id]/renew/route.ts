import { NextRequest, NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;

    const settings = await queryOne<{ loan_period_days: number }>(
      `SELECT COALESCE(loan_period_days, 14)::int AS loan_period_days
       FROM settings
       ORDER BY created_at ASC
       LIMIT 1`,
    );
    const loanPeriodDays = Math.max(1, Number(settings?.loan_period_days || 14));

    const updated = await query(
      `UPDATE loans
       SET returned_date = (
         CASE
           WHEN returned_date IS NOT NULL AND returned_date > CURRENT_DATE
             THEN returned_date
           ELSE CURRENT_DATE
         END
       ) + $1::int
       WHERE id = $2
       RETURNING *`,
      [loanPeriodDays, id],
    );

    if (!updated.length) {
      return NextResponse.json({ error: "Loan not found" }, { status: 404 });
    }

    return NextResponse.json({
      data: updated[0],
      message: `Loan renewed by admin for ${loanPeriodDays} days`,
    });
  } catch (error) {
    console.error("Error renewing loan:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
