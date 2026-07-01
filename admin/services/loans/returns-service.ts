import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(await libraryApi(request, "/loans/active/details"));
  } catch (error) {
    return handleLibraryApiError("Error fetching active returns:", error);
  }
}
