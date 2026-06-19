import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  createFineData,
  listFinesData,
} from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

// GET all fines with pagination and filtering
export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { searchParams } = new URL(request.url);
    return NextResponse.json(
      await listFinesData({
        page: Math.max(1, parseInt(searchParams.get("page") || "1")),
        limit: Math.min(
          100,
          Math.max(1, parseInt(searchParams.get("limit") || "10")),
        ),
        search: searchParams.get("search")?.trim(),
        status: searchParams.get("status")?.trim().toLowerCase() || null,
      }),
    );
  } catch (error) {
    return handleFirebaseServiceError("Error fetching fines:", error);
  }
}

// POST create new fine
export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(
      { data: await createFineData((await request.json()) as Record<string, unknown>) },
      { status: 201 },
    );
  } catch (error) {
    return handleFirebaseServiceError("Error creating fine:", error);
  }
}
