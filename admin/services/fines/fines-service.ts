import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError } from "@/lib/server-api";

// GET all fines with pagination and filtering
export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(
      { error: "Fines are not migrated to PostgreSQL yet." },
      { status: 501 },
    );
  } catch (error) {
    return handleLibraryApiError("Error fetching fines:", error);
  }
}

// POST create new fine
export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(
      { error: "Creating fines is not migrated to PostgreSQL yet." },
      { status: 501 },
    );
  } catch (error) {
    return handleLibraryApiError("Error creating fine:", error);
  }
}
