import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import { User } from "@/lib/types";
import { verifyAdmin } from "@/lib/auth/verify-admin";

// GET all users with pagination and filtering
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);

    const page = parseInt(searchParams.get("page") || "1");
    const limit = parseInt(searchParams.get("limit") || "10");
    const search = searchParams.get("search");

    const offset = (page - 1) * limit;

    let sql = `SELECT * FROM users WHERE 1=1`;
    const params: unknown[] = [];
    let paramIndex = 1;

    if (search) {
      sql += ` AND (name ILIKE $${paramIndex} OR email ILIKE $${paramIndex} OR member_id ILIKE $${paramIndex})`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    // Count total
    const countSql = sql.replace("SELECT *", "SELECT COUNT(*) as count");
    const countResult = await query<{ count: string }>(countSql, params);
    const total = parseInt(countResult[0]?.count || "0");

    sql += ` ORDER BY name ASC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const data = await query<User>(sql, params);

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
    console.error("Error fetching users:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// POST create new user
export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const body = await request.json();

    // Input validation
    if (
      !body.name ||
      typeof body.name !== "string" ||
      body.name.trim().length < 1 ||
      body.name.trim().length > 200
    ) {
      return NextResponse.json(
        { error: "Name is required and must be 1-200 characters" },
        { status: 400 },
      );
    }
    if (
      !body.email ||
      typeof body.email !== "string" ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)
    ) {
      return NextResponse.json(
        { error: "Valid email is required" },
        { status: 400 },
      );
    }
    if (
      body.phone &&
      (typeof body.phone !== "string" ||
        body.phone.length > 20 ||
        !/^[+\d\s()-]+$/.test(body.phone))
    ) {
      return NextResponse.json(
        { error: "Invalid phone number format" },
        { status: 400 },
      );
    }
    if (
      body.address &&
      (typeof body.address !== "string" || body.address.length > 500)
    ) {
      return NextResponse.json(
        { error: "Address must be under 500 characters" },
        { status: 400 },
      );
    }

    const id = `u${Math.floor(100000 + Math.random() * 900000)}`;
    const memberId = `MEM-${Date.now().toString(36).toUpperCase()}`;

    const sql = `
      INSERT INTO users (id, member_id, name, email, phone, address, joined_date)
      VALUES ($1, $2, $3, $4, $5, $6, CURRENT_DATE)
      RETURNING *
    `;

    const data = await query<User>(sql, [
      id,
      memberId,
      body.name,
      body.email,
      body.phone || null,
      body.address || null,
    ]);

    return NextResponse.json({ data: data[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating user:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
