import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  handleLibraryApiError,
  libraryApi,
} from "@/lib/server-api";
import type { LibraryNotification } from "@/lib/types";

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  const requestedLimit = Number(request.nextUrl.searchParams.get("limit") || 50);
  const limit = Number.isFinite(requestedLimit)
    ? Math.max(1, Math.min(Math.trunc(requestedLimit), 100))
    : 50;

  try {
    const [data, count] = await Promise.all([
      libraryApi<LibraryNotification[]>(request, `/notifications?limit=${limit}`),
      libraryApi<{ unread: number }>(request, "/notifications/unread-count"),
    ]);
    return NextResponse.json({ data, unread: count.unread });
  } catch (error) {
    return handleLibraryApiError("Error fetching notifications:", error);
  }
}

export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  const body = await request.json().catch(() => ({}));
  if (body.action !== "read_all") {
    return NextResponse.json(
      { error: "Unsupported notification action" },
      { status: 400 },
    );
  }

  try {
    return NextResponse.json(
      await libraryApi(request, "/notifications/read-all", { method: "POST" }),
    );
  } catch (error) {
    return handleLibraryApiError("Error marking notifications read:", error);
  }
}
