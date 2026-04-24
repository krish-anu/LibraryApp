import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { markAdminNotificationRead } from "@/lib/firebase/notifications";

export async function POST(
  request: NextRequest,
  id: string,
) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  try {
    const notification = await markAdminNotificationRead(id);
    return NextResponse.json({ data: notification });
  } catch (error) {
    console.error("Error marking notification read:", error);
    return NextResponse.json(
      { error: "Failed to update notification" },
      { status: 500 },
    );
  }
}
