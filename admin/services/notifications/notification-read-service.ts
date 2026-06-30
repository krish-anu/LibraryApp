import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  handleLibraryApiError,
  libraryApi,
} from "@/lib/server-api";

export async function POST(request: NextRequest, id: string) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  try {
    return NextResponse.json(
      await libraryApi(
        request,
        `/notifications/${encodeURIComponent(id)}/read`,
        { method: "POST" },
      ),
    );
  } catch (error) {
    return handleLibraryApiError("Error marking notification read:", error);
  }
}
