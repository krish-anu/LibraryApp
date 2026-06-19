import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

// GET settings
export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json({ data: await libraryApi(request, "/settings") });
  } catch (error) {
    return handleLibraryApiError("Error fetching settings:", error);
  }
}

// PUT update settings
export async function PUT(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json({
      data: await libraryApi(request, "/settings", {
        method: "PUT",
        body: JSON.stringify((await request.json()) as Record<string, unknown>),
      }),
    });
  } catch (error) {
    return handleLibraryApiError("Error updating settings:", error);
  }
}
