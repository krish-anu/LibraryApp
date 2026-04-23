import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  createBookData,
  listBooksData,
} from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

// GET all books with pagination and filtering
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    return NextResponse.json(
      await listBooksData({
        page: parseInt(searchParams.get("page") || "1"),
        limit: parseInt(searchParams.get("limit") || "10"),
        category: searchParams.get("category"),
        search: searchParams.get("search"),
        status: searchParams.get("status"),
      }),
    );
  } catch (error) {
    return handleFirebaseServiceError("Error fetching books:", error);
  }
}

// POST create new book
export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(
      { data: await createBookData((await request.json()) as Record<string, unknown>) },
      { status: 201 },
    );
  } catch (error) {
    return handleFirebaseServiceError(
      "Error creating book:",
      error,
      "Failed to create book. Please check your input and try again.",
    );
  }
}
