import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(_request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json(
      await libraryApi(_request, `/loans/renew/${id}`, { method: "POST" }),
    );
  } catch (error) {
    return handleLibraryApiError("Error renewing loan:", error);
  }
}
