import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import { Fine } from "@/lib/types";
import { ensureFineInfrastructure, syncOverdueLoanFines } from "@/lib/fines";
import { verifyAdmin } from "@/lib/auth/verify-admin";

const INSERTABLE_FINE_COLUMNS = new Set([
  "id",
  "member_id",
  "user_id",
  "loan_id",
  "fine_date",
  "fine_amount",
  "amount",
  "status",
  "reason",
  "due_date",
  "created_at",
  "updated_at",
]);

interface FineWithDetails extends Fine {
  user_name?: string;
  user_email?: string;
  book_title?: string;
  payment_date?: string;
  payment_amount?: number;
  payment_handled_by?: string;
  payment_notes?: string;
  total_paid?: number;
  payment_count?: number;
  total_fine_amount?: number;
  user_total_due?: number;
}

async function getFineColumnSet(): Promise<Set<string>> {
  const rows = await query<{ column_name: string }>(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'fines'`,
  );
  return new Set(rows.map((r) => r.column_name));
}

// GET all fines with pagination and filtering
export async function GET(request: NextRequest) {
  try {
    await ensureFineInfrastructure();
    await syncOverdueLoanFines();

    const { searchParams } = new URL(request.url);

    const page = Math.max(1, parseInt(searchParams.get("page") || "1"));
    const limit = Math.min(
      100,
      Math.max(1, parseInt(searchParams.get("limit") || "10")),
    );
    const search = searchParams.get("search")?.trim();
    const status = searchParams.get("status")?.trim().toLowerCase();
    const offset = (page - 1) * limit;

    let fromAndWhere = `
      FROM fines f
      LEFT JOIN users u ON CAST(f.member_id AS TEXT) = CAST(u.id AS TEXT)
      LEFT JOIN loans l ON CAST(f.loan_id AS TEXT) = CAST(l.id AS TEXT)
      LEFT JOIN books b ON CAST(l.book_id AS TEXT) = CAST(b.id AS TEXT)
      LEFT JOIN LATERAL (
        SELECT
          fp.payment_date,
          fp.payment_amount,
          fp.handled_by,
          fp.notes
        FROM fine_payments fp
        WHERE fp.fine_id = f.id
        ORDER BY COALESCE(fp.created_at, fp.payment_date::timestamp) DESC
        LIMIT 1
      ) p ON TRUE
      LEFT JOIN LATERAL (
        SELECT
          COALESCE(SUM(fp2.payment_amount), 0)::float8 AS total_paid,
          COUNT(fp2.id)::int AS payment_count
        FROM fine_payments fp2
        WHERE fp2.fine_id = f.id
      ) ps ON TRUE
      WHERE 1=1
    `;
    const params: unknown[] = [];
    let paramIndex = 1;

    if (search) {
      fromAndWhere += ` AND (
        u.name ILIKE $${paramIndex}
        OR u.email ILIKE $${paramIndex}
        OR b.title ILIKE $${paramIndex}
        OR COALESCE(f.reason, '') ILIKE $${paramIndex}
        OR CAST(f.id AS TEXT) ILIKE $${paramIndex}
        OR CAST(f.member_id AS TEXT) ILIKE $${paramIndex}
        OR COALESCE(CAST(f.loan_id AS TEXT), '') ILIKE $${paramIndex}
        OR COALESCE(p.handled_by, '') ILIKE $${paramIndex}
        OR COALESCE(p.notes, '') ILIKE $${paramIndex}
      )`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    if (status && ["unpaid", "paid", "waived"].includes(status)) {
      fromAndWhere += ` AND LOWER(COALESCE(f.status, 'unpaid')) = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    const countResult = await query<{ count: string }>(
      `SELECT COUNT(*) as count ${fromAndWhere}`,
      params,
    );
    const total = parseInt(countResult[0]?.count || "0");

    const data = await query<FineWithDetails>(
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
        p.handled_by AS payment_handled_by,
        p.notes AS payment_notes,
        COALESCE(ps.total_paid, 0)::float8 AS total_paid,
        COALESCE(ps.payment_count, 0)::int AS payment_count,
        (
          COALESCE(f.fine_amount, 0)::float8 +
          COALESCE(ps.total_paid, 0)::float8
        )::float8 AS total_fine_amount,
        SUM(
          CASE
            WHEN LOWER(COALESCE(f.status, 'unpaid')) = 'unpaid'
              THEN COALESCE(f.fine_amount, 0)::float8
            ELSE 0::float8
          END
        ) OVER (PARTITION BY f.member_id)::float8 AS user_total_due
       ${fromAndWhere}
       ORDER BY COALESCE(f.paid_at, f.fine_date::timestamp, f.created_at) DESC
       LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      [...params, limit, offset],
    );

    return NextResponse.json({
      data,
      totalCount: total,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error("Error fetching fines:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// POST create new fine
export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    await ensureFineInfrastructure();
    const columns = await getFineColumnSet();

    const body = await request.json();
    const memberId =
      typeof body.member_id === "string" ? body.member_id.trim() : "";
    const loanId =
      typeof body.loan_id === "string" && body.loan_id.trim()
        ? body.loan_id.trim()
        : null;
    const reason =
      typeof body.reason === "string" && body.reason.trim()
        ? body.reason.trim()
        : null;
    const dueDate =
      typeof body.due_date === "string" && body.due_date.trim()
        ? body.due_date
        : null;

    if (!memberId) {
      return NextResponse.json(
        { error: "member_id is required" },
        { status: 400 },
      );
    }
    const amount = Number(body.fine_amount);
    if (!Number.isFinite(amount) || amount < 0) {
      return NextResponse.json(
        { error: "fine_amount must be a valid positive number" },
        { status: 400 },
      );
    }

    const id = crypto.randomUUID();
    const insertColumns: string[] = [];
    const insertValues: unknown[] = [];
    const add = (column: string, value: unknown) => {
      if (!INSERTABLE_FINE_COLUMNS.has(column)) return;
      if (!columns.has(column)) return;
      insertColumns.push(column);
      insertValues.push(value);
    };

    add("id", id);
    add("member_id", memberId);
    add("user_id", memberId);
    add("loan_id", loanId);
    add("fine_date", body.fine_date || new Date().toISOString());
    add("fine_amount", amount);
    add("amount", amount);
    add("status", "unpaid");
    add("reason", reason);
    add("due_date", dueDate);
    add("created_at", new Date().toISOString());
    add("updated_at", new Date().toISOString());

    if (!insertColumns.length) {
      return NextResponse.json(
        { error: "fines table has no compatible columns for insert" },
        { status: 500 },
      );
    }

    const placeholders = insertColumns.map((_, i) => `$${i + 1}`).join(", ");
    const data = await query<Fine>(
      `INSERT INTO fines (${insertColumns.join(", ")})
       VALUES (${placeholders})
       RETURNING *`,
      insertValues,
    );

    return NextResponse.json({ data: data[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating fine:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
