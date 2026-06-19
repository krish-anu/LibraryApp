import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  return NextResponse.json(
    { error: "Notifications are not migrated to PostgreSQL yet." },
    { status: 501 },
  );
}

export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  return NextResponse.json(
    { error: "Notifications are not migrated to PostgreSQL yet." },
    { status: 501 },
  );
}
