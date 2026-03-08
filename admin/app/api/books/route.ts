import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import { Book } from "@/lib/types";
import { verifyAdmin } from "@/lib/auth/verify-admin";

const INSERTABLE_BOOK_COLUMNS = new Set([
  "id",
  "title",
  "author",
  "author_id",
  "category_id",
  "description",
  "rating",
  "publication_year",
  "copies_owned",
  "copies_available",
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

// GET all books with pagination and filtering
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const bookColumns = await getBookColumnSet();
    const usesAuthorId =
      bookColumns.has("author_id") && !bookColumns.has("author");

    const page = parseInt(searchParams.get("page") || "1");
    const limit = parseInt(searchParams.get("limit") || "10");
    const category = searchParams.get("category");
    const search = searchParams.get("search");
    const status = searchParams.get("status");

    const offset = (page - 1) * limit;

    const authorSelect = usesAuthorId
      ? `COALESCE(NULLIF(TRIM(CONCAT_WS(' ', a.first_name, a.last_name)), ''), '') AS author`
      : `b.author AS author`;
    const authorJoin = usesAuthorId
      ? `LEFT JOIN authors a ON b.author_id = a.id`
      : ``;
    const authorSearchExpr = usesAuthorId
      ? `TRIM(CONCAT_WS(' ', a.first_name, a.last_name))`
      : `b.author`;

    let fromAndWhere = `
      FROM books b
      LEFT JOIN categories c ON b.category_id = c.id
      ${authorJoin}
      WHERE 1=1
    `;
    const params: unknown[] = [];
    let paramIndex = 1;

    if (category && category !== "all") {
      fromAndWhere += ` AND b.category_id = $${paramIndex}`;
      params.push(category);
      paramIndex++;
    }

    if (search) {
      fromAndWhere += ` AND (b.title ILIKE $${paramIndex} OR ${authorSearchExpr} ILIKE $${paramIndex})`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    if (status) {
      if (status === "available") {
        if (bookColumns.has("copies_available")) {
          fromAndWhere += ` AND COALESCE(b.copies_available, 0) > 0`;
        } else if (bookColumns.has("status")) {
          fromAndWhere += ` AND LOWER(COALESCE(b.status, '')) = 'available'`;
        } else {
          fromAndWhere += ` AND COALESCE(b.copies_owned, 0) > 0`;
        }
      } else if (status === "not_available") {
        if (bookColumns.has("copies_available")) {
          fromAndWhere += ` AND COALESCE(b.copies_available, 0) <= 0`;
        } else if (bookColumns.has("status")) {
          fromAndWhere += ` AND LOWER(COALESCE(b.status, '')) <> 'available'`;
        } else {
          fromAndWhere += ` AND COALESCE(b.copies_owned, 0) <= 0`;
        }
      } else if (bookColumns.has("status")) {
        fromAndWhere += ` AND LOWER(COALESCE(b.status, '')) = LOWER($${paramIndex})`;
        params.push(status);
        paramIndex++;
      }
    }

    const countSql = `SELECT COUNT(*) as count ${fromAndWhere}`;
    const countResult = await query<{ count: string }>(countSql, params);
    const total = parseInt(countResult[0]?.count || "0");

    const selectSql = `
      SELECT b.*, c.name as category, ${authorSelect}
      ${fromAndWhere}
      ORDER BY b.title ASC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;
    params.push(limit, offset);

    const data = await query<Book>(selectSql, params);

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
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const body = await request.json();

    // Input validation
    if (
      !body.title ||
      typeof body.title !== "string" ||
      body.title.trim().length < 1 ||
      body.title.trim().length > 500
    ) {
      return NextResponse.json(
        { error: "Title is required and must be 1-500 characters" },
        { status: 400 },
      );
    }
    if (body.rating !== undefined && body.rating !== null) {
      const rating = Number(body.rating);
      if (isNaN(rating) || rating < 0 || rating > 5) {
        return NextResponse.json(
          { error: "Rating must be between 0 and 5" },
          { status: 400 },
        );
      }
    }
    if (body.publication_year !== undefined && body.publication_year !== null) {
      const year = Number(body.publication_year);
      if (isNaN(year) || year < 0 || year > new Date().getFullYear() + 1) {
        return NextResponse.json(
          { error: "Invalid publication year" },
          { status: 400 },
        );
      }
    }
    if (body.pages !== undefined && body.pages !== null) {
      const pages = Number(body.pages);
      if (isNaN(pages) || pages < 1 || pages > 100000) {
        return NextResponse.json(
          { error: "Pages must be between 1 and 100000" },
          { status: 400 },
        );
      }
    }
    if (body.copies_owned !== undefined && body.copies_owned !== null) {
      const copies = Number(body.copies_owned);
      if (isNaN(copies) || copies < 0 || copies > 10000) {
        return NextResponse.json(
          { error: "Copies owned must be between 0 and 10000" },
          { status: 400 },
        );
      }
    }

    const id = crypto.randomUUID();
    const columns = await getBookColumnSet();
    const usesAuthorId = columns.has("author_id") && !columns.has("author");

    const insertColumns: string[] = [];
    const insertValues: unknown[] = [];
    const add = (column: string, value: unknown) => {
      if (!INSERTABLE_BOOK_COLUMNS.has(column)) return;
      if (!columns.has(column)) return;
      insertColumns.push(column);
      insertValues.push(value);
    };

    if (!columns.has("title")) {
      throw new Error("books.title column is missing");
    }

    add("id", id);
    add("title", body.title);
    if (usesAuthorId) {
      const authorText =
        typeof body.author === "string" ? body.author.trim() : "";
      const authorId = authorText
        ? await resolveAuthorIdByName(authorText)
        : null;
      add("author_id", authorId);
    } else {
      add("author", body.author);
    }
    add("category_id", body.category_id || null);
    add("description", body.description || null);
    add("rating", body.rating || null);
    add("publication_year", body.publication_year || null);

    const copiesOwned = body.copies_owned || 1;
    add("copies_owned", copiesOwned);
    add("copies_available", copiesOwned);

    // Support both schema variants.
    add("image", body.image || null);
    add("cover_image_url", body.image || null);

    add("language", body.language || "English");
    add("pages", body.pages || null);

    if (!insertColumns.length) {
      throw new Error("No compatible columns found for books insert");
    }

    const placeholders = insertColumns.map((_, i) => `$${i + 1}`).join(", ");
    const sql = `
      INSERT INTO books (${insertColumns.join(", ")})
      VALUES (${placeholders})
      RETURNING *
    `;

    await query<Book>(sql, insertValues);

    const readAuthorSelect = usesAuthorId
      ? `COALESCE(NULLIF(TRIM(CONCAT_WS(' ', a.first_name, a.last_name)), ''), '') AS author`
      : `b.author AS author`;
    const readAuthorJoin = usesAuthorId
      ? `LEFT JOIN authors a ON b.author_id = a.id`
      : ``;
    const data = await query<Book>(
      `SELECT b.*, c.name as category, ${readAuthorSelect}
       FROM books b
       LEFT JOIN categories c ON b.category_id = c.id
       ${readAuthorJoin}
       WHERE b.id = $1`,
      [id],
    );

    return NextResponse.json({ data: data[0] }, { status: 201 });
  } catch (error: unknown) {
    console.error("Error creating book:", error);
    return NextResponse.json(
      {
        error: "Failed to create book. Please check your input and try again.",
      },
      { status: 500 },
    );
  }
}
