import { NextResponse } from "next/server";
import { getDashboardData } from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

export async function GET() {
  try {
    return NextResponse.json(await getDashboardData());
  } catch (error) {
    return handleFirebaseServiceError("Error fetching dashboard stats:", error);
  }
}
