import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

// GET all users with pagination and filtering
export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { searchParams } = new URL(request.url);
    return NextResponse.json(
      await libraryApi(request, "/users", {
        headers: {
          "X-Page": searchParams.get("page") || "1",
          "X-Limit": searchParams.get("limit") || "10",
          "X-Search": searchParams.get("search") || "",
          "X-Status": searchParams.get("status") || "",
        },
      }),
    );
  } catch (error) {
    return handleLibraryApiError("Error fetching users:", error);
  }
}

// POST create new user
export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(
      { error: "Creating users is not migrated to PostgreSQL yet." },
      { status: 501 },
    );
  } catch (error) {
    return handleLibraryApiError("Error creating user:", error);
  }
}
