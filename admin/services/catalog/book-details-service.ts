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

function adminCoverUrl(value?: string) {
  const image = (value || "").trim();
  return /^(https?:\/\/|data:|blob:|\/)/.test(image) ? image : "";
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
    image: adminCoverUrl(book.image),
    language: book.language || "English",
    pages: toNumber(book.pages, 0),
    rating_count: toNumber(book.rating_count, 0),
  };
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

// GET single book
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    const [book, categories] = await Promise.all([
      libraryApi<ApiBook>(request, `/books/${encodeURIComponent(id)}`),
      libraryApi<Category[]>(request, "/categories"),
    ]);
    return NextResponse.json({ data: normalizeBook(book, categories) });
  } catch (error) {
    return handleLibraryApiError("Error fetching book:", error);
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
    const categories = await libraryApi<Category[]>(request, "/categories");
    const updatedBook = await libraryApi<ApiBook>(
      request,
      `/books/${encodeURIComponent(id)}`,
      {
        method: "PUT",
        body: JSON.stringify(
          bookPayload((await request.json()) as Record<string, unknown>, categories),
        ),
      },
    );
    return NextResponse.json({
      data: normalizeBook(updatedBook, categories),
    });
  } catch (error) {
    return handleLibraryApiError("Error updating book:", error);
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
    await libraryApi<void>(request, `/books/${encodeURIComponent(id)}`, {
      method: "DELETE",
    });
    return NextResponse.json({ success: true });
  } catch (error) {
    return handleLibraryApiError("Error deleting book:", error);
  }
}
