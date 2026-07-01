import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const status = request.nextUrl.searchParams.get("status");
    const query = status ? `?status=${encodeURIComponent(status)}` : "";
    return NextResponse.json(await libraryApi(request, `/loans/history${query}`));
  } catch (error) {
    return handleLibraryApiError("Error fetching loan history:", error);
  }
}
