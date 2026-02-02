import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import { Book } from "@/lib/types";

// GET all books with pagination and filtering
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);

    const page = parseInt(searchParams.get("page") || "1");
    const limit = parseInt(searchParams.get("limit") || "10");
    const category = searchParams.get("category");
    const search = searchParams.get("search");

    const offset = (page - 1) * limit;

    let sql = `
      SELECT b.*, c.name as category 
      FROM books b 
      LEFT JOIN categories c ON b.category_id = c.id 
      WHERE 1=1
    `;
    const params: unknown[] = [];
    let paramIndex = 1;

    if (category && category !== "all") {
      sql += ` AND b.category_id = $${paramIndex}`;
      params.push(category);
      paramIndex++;
    }

    if (search) {
      sql += ` AND (b.title ILIKE $${paramIndex} OR b.author ILIKE $${paramIndex})`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    // Count total
    const countSql = sql.replace('SELECT b.*, c.name as category', 'SELECT COUNT(*) as count');
    const countResult = await query<{ count: string }>(countSql, params);
    const total = parseInt(countResult[0]?.count || '0');

    sql += ` ORDER BY b.title ASC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const data = await query<Book>(sql, params);

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
    console.error("Error fetching books:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// POST create new book
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const id = crypto.randomUUID();

    const sql = `
      INSERT INTO books (id, title, author, category_id, description, rating, publication_year, copies_owned, image, language, pages)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *
    `;
    
    const data = await query<Book>(sql, [
      id,
      body.title,
      body.author,
      body.category_id || null,
      body.description || null,
      body.rating || null,
      body.publication_year || null,
      body.copies_owned || 1,
      body.image || null,
      body.language || 'English',
      body.pages || null,
    ]);

    return NextResponse.json({ data: data[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating book:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
