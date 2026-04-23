import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  createUserData,
  listUsersData,
} from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

// GET all users with pagination and filtering
export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { searchParams } = new URL(request.url);
    return NextResponse.json(
      await listUsersData({
        page: parseInt(searchParams.get("page") || "1"),
        limit: parseInt(searchParams.get("limit") || "10"),
        search: searchParams.get("search"),
        status: searchParams.get("status"),
      }),
    );
  } catch (error) {
    return handleFirebaseServiceError("Error fetching users:", error);
  }
}

// POST create new user
export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(
      { data: await createUserData((await request.json()) as Record<string, unknown>) },
      { status: 201 },
    );
  } catch (error) {
    return handleFirebaseServiceError("Error creating user:", error);
  }
}
