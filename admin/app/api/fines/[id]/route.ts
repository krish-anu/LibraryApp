import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import { Fine } from "@/lib/types";

// GET single fine
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;

    const data = await query<Fine>(
      `SELECT 
        f.*,
        u.name as user_name,
        u.email as user_email,
        b.title as book_title
      FROM fines f
      LEFT JOIN users u ON f.member_id = u.id
      LEFT JOIN loans l ON f.loan_id = l.id
      LEFT JOIN books b ON l.book_id = b.id
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
  try {
    const { id } = await params;
    const body = await request.json();

    const data = await query<Fine>(
      `UPDATE fines SET 
        fine_amount = COALESCE($1, fine_amount),
        fine_date = COALESCE($2, fine_date)
      WHERE id = $3
      RETURNING *`,
      [body.fine_amount, body.fine_date, id],
    );

    if (!data.length) {
      return NextResponse.json({ error: "Fine not found" }, { status: 404 });
    }

    return NextResponse.json({ data: data[0] });
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
  try {
    const { id } = await params;

    await query("DELETE FROM fines WHERE id = $1", [id]);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error deleting fine:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
