import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { getDashboardData } from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(await getDashboardData());
  } catch (error) {
    return handleFirebaseServiceError("Error fetching dashboard stats:", error);
  }
}
