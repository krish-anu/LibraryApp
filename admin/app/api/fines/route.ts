import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import { Fine } from "@/lib/types";

interface FineWithDetails extends Fine {
  user_name?: string;
  user_email?: string;
  book_title?: string;
}

// GET all fines with pagination and filtering
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);

    const page = parseInt(searchParams.get("page") || "1");
    const limit = parseInt(searchParams.get("limit") || "10");
    const offset = (page - 1) * limit;

    // Get fines with user and loan/book info
    const data = await query<FineWithDetails>(
      `SELECT 
        f.*,
        u.name as user_name,
        u.email as user_email,
        b.title as book_title
      FROM fines f
      LEFT JOIN users u ON f.member_id = u.id
      LEFT JOIN loans l ON f.loan_id = l.id
      LEFT JOIN books b ON l.book_id = b.id
      ORDER BY f.fine_date DESC
      LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    // Get total count
    const countResult = await query<{ count: string }>(
      "SELECT COUNT(*) as count FROM fines"
    );
    const total = parseInt(countResult[0]?.count || '0');

    return NextResponse.json({
      data,
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
  try {
    const body = await request.json();

    const data = await query<Fine>(
      `INSERT INTO fines (id, member_id, loan_id, fine_date, fine_amount)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *`,
      [
        crypto.randomUUID(),
        body.member_id,
        body.loan_id,
        body.fine_date || new Date().toISOString(),
        body.fine_amount,
      ]
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
