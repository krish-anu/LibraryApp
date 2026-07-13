import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json({
      data: await libraryApi(request, "/content-sync/run", {
        method: "POST",
      }),
    });
  } catch (error) {
    return handleLibraryApiError("Error running sheet sync:", error);
  }
}
