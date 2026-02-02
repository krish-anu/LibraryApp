import { NextRequest, NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";
import { User } from "@/lib/types";

// GET single user with stats
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;

    const user = await queryOne<User>("SELECT * FROM users WHERE id = $1", [id]);

    if (!user) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }

    // Get user's active loans count
    const loansResult = await queryOne<{ count: string }>(
      "SELECT COUNT(*) as count FROM loans WHERE member_id = $1 AND returned_date IS NULL",
      [id]
    );

    // Get user's total unpaid fines
    const finesResult = await queryOne<{ total: string }>(
      "SELECT COALESCE(SUM(fine_amount), 0) as total FROM fines WHERE member_id = $1",
      [id]
    );

    return NextResponse.json({
      data: {
        ...user,
        active_loans: parseInt(loansResult?.count || '0'),
        total_fines: parseFloat(finesResult?.total || '0'),
      },
    });
  } catch (error) {
    console.error("Error fetching user:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// PUT update user
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    const body = await request.json();

    const data = await query<User>(
      `UPDATE users SET 
        name = COALESCE($1, name),
        email = COALESCE($2, email),
        phone = COALESCE($3, phone),
        address = COALESCE($4, address),
        updated_at = NOW()
      WHERE id = $5
      RETURNING *`,
      [body.name, body.email, body.phone, body.address, id]
    );

    if (!data.length) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }

    return NextResponse.json({ data: data[0] });
  } catch (error) {
    console.error("Error updating user:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// DELETE user
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;

    await query("DELETE FROM users WHERE id = $1", [id]);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error deleting user:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
