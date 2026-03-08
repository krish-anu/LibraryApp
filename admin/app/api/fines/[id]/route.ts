import { NextRequest, NextResponse } from "next/server";
import { getClient, query } from "@/lib/db";
import { Fine } from "@/lib/types";
import { ensureFineInfrastructure } from "@/lib/fines";
import { verifyAdmin } from "@/lib/auth/verify-admin";

type FineStatus = "unpaid" | "paid" | "waived";

function parseFineStatus(value: unknown): FineStatus | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  if (normalized === "unpaid" || normalized === "paid" || normalized === "waived") {
    return normalized;
  }
  return null;
}

function nonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

// GET single fine
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    await ensureFineInfrastructure();
    const { id } = await params;

    const data = await query<Fine>(
      `SELECT
        f.id,
        f.member_id,
        f.loan_id,
        f.fine_date,
        f.fine_amount::float8 AS fine_amount,
        COALESCE(f.status, 'unpaid') AS status,
        f.reason,
        f.due_date,
        f.paid_at,
        f.payment_method,
        f.created_at,
        f.updated_at,
        u.name AS user_name,
        u.email AS user_email,
        b.title AS book_title,
        p.payment_date,
        p.payment_amount::float8 AS payment_amount,
        p.payment_method AS payment_record_method,
        p.handled_by AS payment_handled_by,
        p.notes AS payment_notes
      FROM fines f
      LEFT JOIN users u ON CAST(f.member_id AS TEXT) = CAST(u.id AS TEXT)
      LEFT JOIN loans l ON CAST(f.loan_id AS TEXT) = CAST(l.id AS TEXT)
      LEFT JOIN books b ON CAST(l.book_id AS TEXT) = CAST(b.id AS TEXT)
      LEFT JOIN LATERAL (
        SELECT
          fp.payment_date,
          fp.payment_amount,
          fp.payment_method,
          fp.handled_by,
          fp.notes
        FROM fine_payments fp
        WHERE fp.fine_id = f.id
        ORDER BY COALESCE(fp.created_at, fp.payment_date::timestamp) DESC
        LIMIT 1
      ) p ON TRUE
      WHERE f.id = $1`,
      [id],
    );

    if (!data.length) {
      return NextResponse.json({ error: "Fine not found" }, { status: 404 });
    }

    return NextResponse.json({ data: data[0] });
  } catch (error) {
    console.error("Error fetching fine:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// PUT update fine
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    await ensureFineInfrastructure();
    const { id } = await params;
    const body = await request.json();
    const hasStatusField = Object.prototype.hasOwnProperty.call(body, "status");
    const requestedStatus = parseFineStatus(body.status);
    if (hasStatusField && !requestedStatus) {
      return NextResponse.json(
        { error: "status must be one of: unpaid, paid, waived" },
        { status: 400 },
      );
    }

    const paymentMethod = nonEmptyString(body.payment_method);
    if (paymentMethod && paymentMethod.toLowerCase() !== "physical") {
      return NextResponse.json(
        { error: "Only physical fine payments are supported" },
        { status: 400 },
      );
    }

    const fineAmount =
      body.fine_amount === undefined ? null : Number(body.fine_amount);
    if (fineAmount !== null && (!Number.isFinite(fineAmount) || fineAmount < 0)) {
      return NextResponse.json(
        { error: "fine_amount must be a valid positive number" },
        { status: 400 },
      );
    }

    const paymentAmount =
      body.payment_amount === undefined ? null : Number(body.payment_amount);
    if (
      paymentAmount !== null &&
      (!Number.isFinite(paymentAmount) || paymentAmount < 0)
    ) {
      return NextResponse.json(
        { error: "payment_amount must be a valid positive number" },
        { status: 400 },
      );
    }

    const fineDate = nonEmptyString(body.fine_date);
    const dueDate = nonEmptyString(body.due_date);
    const reason = nonEmptyString(body.reason);
    const requestedPaidAt = nonEmptyString(body.paid_at);
    if (requestedPaidAt && Number.isNaN(Date.parse(requestedPaidAt))) {
      return NextResponse.json(
        { error: "paid_at must be a valid date/time" },
        { status: 400 },
      );
    }

    const client = await getClient();
    try {
      await client.query("BEGIN");

      const fineResult = await client.query<{
        id: string;
        member_id: string;
        fine_amount: number;
        status: string;
      }>(
        `SELECT
          id,
          member_id,
          COALESCE(fine_amount, 0)::float8 AS fine_amount,
          LOWER(COALESCE(status, 'unpaid')) AS status
         FROM fines
         WHERE id = $1
         FOR UPDATE`,
        [id],
      );

      if (!fineResult.rows.length) {
        await client.query("ROLLBACK");
        return NextResponse.json({ error: "Fine not found" }, { status: 404 });
      }

      const currentFine = fineResult.rows[0];
      const currentStatus = parseFineStatus(currentFine.status) || "unpaid";
      const nextStatus = requestedStatus ?? currentStatus;
      const isPaymentRequest = paymentAmount !== null;

      if (isPaymentRequest) {
        if (currentStatus === "waived") {
          await client.query("ROLLBACK");
          return NextResponse.json(
            { error: "Cannot accept payments for a waived fine" },
            { status: 400 },
          );
        }

        const outstanding = Number(currentFine.fine_amount || 0);
        if (outstanding <= 0) {
          await client.query("ROLLBACK");
          return NextResponse.json(
            { error: "This fine has no remaining balance" },
            { status: 400 },
          );
        }

        const appliedPayment = Math.min(paymentAmount, outstanding);
        if (!Number.isFinite(appliedPayment) || appliedPayment <= 0) {
          await client.query("ROLLBACK");
          return NextResponse.json(
            { error: "payment_amount must be greater than 0" },
            { status: 400 },
          );
        }

        const remainingAmount = Math.max(0, outstanding - appliedPayment);
        const paymentStatus: FineStatus =
          remainingAmount <= 0.00001 ? "paid" : "unpaid";
        const paidAtDate = requestedPaidAt
          ? new Date(requestedPaidAt)
          : new Date();
        const paymentDate = paidAtDate.toISOString().slice(0, 10);

        const updatedFineResult = await client.query<Fine>(
          `UPDATE fines SET
            fine_amount = $1,
            fine_date = COALESCE($2, fine_date),
            reason = COALESCE($3, reason),
            due_date = COALESCE($4, due_date),
            status = $5,
            paid_at = CASE
              WHEN $5 = 'paid' THEN COALESCE($6::timestamp, NOW())
              ELSE NULL
            END,
            payment_method = 'physical',
            updated_at = NOW()
           WHERE id = $7
           RETURNING *`,
          [
            remainingAmount,
            fineDate,
            reason,
            dueDate,
            paymentStatus,
            requestedPaidAt,
            id,
          ],
        );

        const updatedFine = updatedFineResult.rows[0];

        await client.query(
          `INSERT INTO fine_payments (
            id,
            fine_id,
            member_id,
            payment_date,
            payment_amount,
            payment_method,
            handled_by,
            notes,
            created_at
          ) VALUES ($1, $2, $3, $4, $5, 'physical', $6, $7, NOW())`,
          [
            crypto.randomUUID(),
            id,
            currentFine.member_id,
            paymentDate,
            appliedPayment,
            "admin",
            nonEmptyString(body.notes),
          ],
        );

        await client.query("COMMIT");
        return NextResponse.json({
          data: updatedFine,
          payment: {
            appliedAmount: appliedPayment,
            remainingAmount,
          },
        });
      }

      const resolvedFineAmount =
        fineAmount ?? (nextStatus === "paid" ? 0 : null);

      const updatedFineResult = await client.query<Fine>(
        `UPDATE fines SET
          fine_amount = COALESCE($1, fine_amount),
          fine_date = COALESCE($2, fine_date),
          reason = COALESCE($3, reason),
          due_date = COALESCE($4, due_date),
          status = $5,
          paid_at = CASE
            WHEN $5 = 'paid' THEN COALESCE($6::timestamp, paid_at, NOW())
            WHEN $5 IN ('unpaid', 'waived') THEN NULL
            ELSE paid_at
          END,
          payment_method = CASE
            WHEN $5 = 'paid' THEN 'physical'
            WHEN $5 IN ('unpaid', 'waived') THEN NULL
            ELSE payment_method
          END,
          updated_at = NOW()
         WHERE id = $7
         RETURNING *`,
        [resolvedFineAmount, fineDate, reason, dueDate, nextStatus, requestedPaidAt, id],
      );

      const updatedFine = updatedFineResult.rows[0];

      if (nextStatus === "paid" && currentStatus !== "paid") {
        const paidAtDate = requestedPaidAt
          ? new Date(requestedPaidAt)
          : new Date();
        const paymentDate = paidAtDate.toISOString().slice(0, 10);
        const paymentTotal = Number(currentFine.fine_amount || 0);

        await client.query(
          `INSERT INTO fine_payments (
            id,
            fine_id,
            member_id,
            payment_date,
            payment_amount,
            payment_method,
            handled_by,
            notes,
            created_at
          ) VALUES ($1, $2, $3, $4, $5, 'physical', $6, $7, NOW())`,
          [
            crypto.randomUUID(),
            id,
            currentFine.member_id,
            paymentDate,
            paymentTotal,
            "admin",
            nonEmptyString(body.notes),
          ],
        );
      }

      await client.query("COMMIT");
      return NextResponse.json({ data: updatedFine });
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error("Error updating fine:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// DELETE fine
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    await ensureFineInfrastructure();
    const { id } = await params;

    await query("DELETE FROM fine_payments WHERE fine_id = $1", [id]);
    const deleted = await query<Fine>(
      "DELETE FROM fines WHERE id = $1 RETURNING *",
      [id],
    );
    if (!deleted.length) {
      return NextResponse.json({ error: "Fine not found" }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: deleted[0] });
  } catch (error) {
    console.error("Error deleting fine:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
