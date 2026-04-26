import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  adminUnreadNotificationCount,
  listAdminNotifications,
  markAllAdminNotificationsRead,
} from "@/lib/firebase/notifications";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  try {
    const limitParam = Number(request.nextUrl.searchParams.get("limit") || "50");
    const limit = Number.isFinite(limitParam)
      ? Math.max(1, Math.min(100, limitParam))
      : 50;

    const [notifications, unread] = await Promise.all([
      listAdminNotifications(limit),
      adminUnreadNotificationCount(),
    ]);

    return NextResponse.json({ data: notifications, unread });
  } catch (error) {
    return handleFirebaseServiceError("Error fetching notifications:", error);
  }
}

export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  try {
    const body = await request.json().catch(() => ({}));
    if (body?.action === "read_all") {
      const marked = await markAllAdminNotificationsRead();
      return NextResponse.json({ success: true, marked });
    }

    return NextResponse.json({ error: "Unsupported action" }, { status: 400 });
  } catch (error) {
    return handleFirebaseServiceError("Error updating notifications:", error);
  }
}
