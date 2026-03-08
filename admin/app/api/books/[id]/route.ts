import { NextRequest, NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";
import { Book } from "@/lib/types";
import { verifyAdmin } from "@/lib/auth/verify-admin";

const UPDATABLE_BOOK_COLUMNS = new Set([
  "title",
  "author",
  "author_id",
  "category_id",
  "description",
  "rating",
  "publication_year",
  "copies_owned",
  "image",
  "cover_image_url",
  "language",
  "pages",
]);

async function getBookColumnSet(): Promise<Set<string>> {
  const rows = await query<{ column_name: string }>(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'books'`,
  );
  return new Set(rows.map((r) => r.column_name));
}

async function resolveAuthorIdByName(authorName: string): Promise<string> {
  const normalized = authorName.trim();
  const found = await query<{ id: string }>(
    `SELECT id
     FROM authors
     WHERE TRIM(CONCAT_WS(' ', COALESCE(first_name, ''), COALESCE(last_name, ''))) ILIKE $1
     LIMIT 1`,
    [normalized],
  );
  if (found[0]?.id) return found[0].id;

  const id = crypto.randomUUID();
  const created = await query<{ id: string }>(
    `INSERT INTO authors (id, first_name, last_name)
     VALUES ($1, $2, $3)
     RETURNING id`,
    [id, normalized, ""],
  );
  return created[0].id;
}

async function getBookById(id: string): Promise<Book | null> {
  const columns = await getBookColumnSet();
  const usesAuthorId = columns.has("author_id") && !columns.has("author");
  const authorSelect = usesAuthorId
    ? `COALESCE(NULLIF(TRIM(CONCAT_WS(' ', a.first_name, a.last_name)), ''), '') AS author`
    : `b.author AS author`;
  const authorJoin = usesAuthorId
    ? `LEFT JOIN authors a ON b.author_id = a.id`
    : ``;

  return queryOne<Book>(
    `SELECT b.*, c.name as category, ${authorSelect}
     FROM books b
     LEFT JOIN categories c ON b.category_id = c.id
     ${authorJoin}
     WHERE b.id = $1`,
    [id],
  );
}

// GET single book
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    const data = await getBookById(id);

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
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    const body = await request.json();
    const columns = await getBookColumnSet();
    const usesAuthorId = columns.has("author_id") && !columns.has("author");

    const updates: string[] = [];
    const values: unknown[] = [];
    const addUpdate = (column: string, value: unknown) => {
      if (!UPDATABLE_BOOK_COLUMNS.has(column)) return;
      if (!columns.has(column) || value === undefined) return;
      values.push(value);
      updates.push(`${column} = $${values.length}`);
    };

    addUpdate("title", body.title);
    addUpdate("category_id", body.category_id);
    addUpdate("description", body.description);
    addUpdate("rating", body.rating);
    addUpdate("publication_year", body.publication_year);
    addUpdate("copies_owned", body.copies_owned);
    addUpdate("image", body.image);
    addUpdate("cover_image_url", body.image);
    addUpdate("language", body.language);
    addUpdate("pages", body.pages);

    if (typeof body.author === "string") {
      if (usesAuthorId) {
        const trimmed = body.author.trim();
        const authorId = trimmed ? await resolveAuthorIdByName(trimmed) : null;
        addUpdate("author_id", authorId);
      } else {
        addUpdate("author", body.author);
      }
    }

    if (!updates.length) {
      const existing = await getBookById(id);
      if (!existing) {
        return NextResponse.json({ error: "Book not found" }, { status: 404 });
      }
      return NextResponse.json({ data: existing });
    }

    values.push(id);
    const updated = await query<Book>(
      `UPDATE books SET ${updates.join(", ")}
       WHERE id = $${values.length}
       RETURNING id`,
      values,
    );

    if (!updated.length) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 });
    }
    const data = await getBookById(id);
    return NextResponse.json({ data });
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
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

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
