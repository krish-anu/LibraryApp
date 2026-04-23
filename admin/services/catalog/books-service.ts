import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";
import type { Book, Category } from "@/lib/types";

type ApiBook = {
  id: string;
  title?: string;
  author?: string;
  category?: string;
  description?: string;
  rating?: number;
  publication_year?: number;
  copies_owned?: number;
  image?: string;
  language?: string;
  pages?: number;
  rating_count?: number;
};

function toNumber(value: unknown, fallback: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeBook(book: ApiBook, categories: Category[]): Book {
  const category = categories.find((entry) => entry.name === book.category);
  const copiesOwned = toNumber(book.copies_owned, 0);

  return {
    id: book.id,
    title: book.title || "",
    author: book.author || "",
    category: book.category || "",
    category_id: category?.id || "",
    description: book.description || "",
    rating: toNumber(book.rating, 0),
    publication_year: toNumber(book.publication_year, 0),
    copies_owned: copiesOwned,
    copies_available: copiesOwned,
    status: copiesOwned > 0 ? "available" : "not_available",
    image: book.image || "",
    language: book.language || "English",
    pages: toNumber(book.pages, 0),
    rating_count: toNumber(book.rating_count, 0),
  };
}

function matchesSearch(book: Book, search: string | null) {
  const query = (search || "").trim().toLowerCase();
  if (!query) return true;
  return [book.title, book.author, book.category, book.description].some((value) =>
    String(value || "").toLowerCase().includes(query),
  );
}

function matchesStatus(book: Book, status: string | null) {
  if (!status) return true;
  if (status === "available") return (book.copies_available || 0) > 0;
  if (status === "not_available") return (book.copies_available || 0) <= 0;
  return true;
}

function bookPayload(
  payload: Record<string, unknown>,
  categories: Category[],
) {
  const category = categories.find(
    (entry) => entry.id === payload.category_id || entry.name === payload.category,
  );

  return {
    title: String(payload.title || ""),
    author: String(payload.author || ""),
    category: String(category?.name || payload.category || "Uncategorized"),
    description: String(payload.description || ""),
    rating: toNumber(payload.rating, 0),
    publication_year: toNumber(
      payload.publication_year,
      new Date().getFullYear(),
    ),
    copies_owned: toNumber(payload.copies_owned, 0),
    image: String(payload.image || ""),
    language: String(payload.language || "English"),
    pages: toNumber(payload.pages, 200),
    rating_count: toNumber(payload.rating_count, 0),
  };
}

// GET all books with pagination and filtering
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get("page") || "1");
    const limit = parseInt(searchParams.get("limit") || "10");
    const category = searchParams.get("category");
    const search = searchParams.get("search");
    const status = searchParams.get("status");
    const [apiBooks, categories] = await Promise.all([
      libraryApi<ApiBook[]>(request, "/books"),
      libraryApi<Category[]>(request, "/categories"),
    ]);

    const filteredBooks = apiBooks
      .map((book) => normalizeBook(book, categories))
      .filter((book) => !category || book.category_id === category)
      .filter((book) => matchesSearch(book, search))
      .filter((book) => matchesStatus(book, status));

    const start = Math.max(0, (page - 1) * limit);

    return NextResponse.json(
      {
        data: filteredBooks.slice(start, start + limit),
        totalCount: filteredBooks.length,
      },
    );
  } catch (error) {
    return handleLibraryApiError("Error fetching books:", error);
  }
}

// POST create new book
export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const categories = await libraryApi<Category[]>(request, "/categories");
    const createdBook = await libraryApi<ApiBook>(request, "/books", {
      method: "POST",
      body: JSON.stringify(
        bookPayload((await request.json()) as Record<string, unknown>, categories),
      ),
    });

    return NextResponse.json({
      data: normalizeBook(createdBook, categories),
    }, { status: 201 });
  } catch (error) {
    return handleLibraryApiError(
      "Error creating book:",
      error,
    );
  }
}
