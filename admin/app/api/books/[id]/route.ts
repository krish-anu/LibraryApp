import { NextRequest, NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";
import { Book } from "@/lib/types";

// GET single book
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    
    const data = await queryOne<Book>(
      `SELECT b.*, c.name as category 
       FROM books b 
       LEFT JOIN categories c ON b.category_id = c.id 
       WHERE b.id = $1`,
      [id]
    );

    if (!data) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 });
    }

    return NextResponse.json({ data });
  } catch (error) {
    console.error("Error fetching book:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// PUT update book
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    const body = await request.json();

    const data = await query<Book>(
      `UPDATE books SET 
        title = COALESCE($1, title),
        author = COALESCE($2, author),
        category_id = COALESCE($3, category_id),
        description = COALESCE($4, description),
        rating = COALESCE($5, rating),
        publication_year = COALESCE($6, publication_year),
        copies_owned = COALESCE($7, copies_owned),
        image = COALESCE($8, image),
        language = COALESCE($9, language),
        pages = COALESCE($10, pages)
      WHERE id = $11
      RETURNING *`,
      [
        body.title,
        body.author,
        body.category_id,
        body.description,
        body.rating,
        body.publication_year,
        body.copies_owned,
        body.image,
        body.language,
        body.pages,
        id
      ]
    );

    if (!data.length) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 });
    }

    return NextResponse.json({ data: data[0] });
  } catch (error) {
    console.error("Error updating book:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// DELETE book
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    
    await query("DELETE FROM books WHERE id = $1", [id]);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error deleting book:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
