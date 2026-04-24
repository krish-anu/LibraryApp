import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  adminUnreadNotificationCount,
  listAdminNotifications,
  markAllAdminNotificationsRead,
} from "@/lib/firebase/notifications";

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  const limitParam = Number(request.nextUrl.searchParams.get("limit") || "50");
  const limit = Number.isFinite(limitParam)
    ? Math.max(1, Math.min(100, limitParam))
    : 50;

  const [notifications, unread] = await Promise.all([
    listAdminNotifications(limit),
    adminUnreadNotificationCount(),
  ]);

  return NextResponse.json({ data: notifications, unread });
}

export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  const body = await request.json().catch(() => ({}));
  if (body?.action === "read_all") {
    const marked = await markAllAdminNotificationsRead();
    return NextResponse.json({ success: true, marked });
  }

  return NextResponse.json({ error: "Unsupported action" }, { status: 400 });
}
