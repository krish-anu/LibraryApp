import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";

export async function POST(request: NextRequest, id: string) {
  const auth = await verifyAdmin(request);
  if ("error" in auth) return auth.error;

  return NextResponse.json(
    { error: `Notification ${id} is not migrated to PostgreSQL yet.` },
    { status: 501 },
  );
}
