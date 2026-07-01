import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    const payload = await request.json().catch(() => ({}));
    return NextResponse.json(
      await libraryApi(request, `/loans/return/${id}`, {
        method: "POST",
        body: JSON.stringify(payload),
      }),
    );
  } catch (error) {
    return handleLibraryApiError("Error returning loan:", error);
  }
}
