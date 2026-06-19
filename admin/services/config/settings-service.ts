import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  getSettingsData,
  updateSettingsData,
} from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

// GET settings
export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json({ data: await getSettingsData() });
  } catch (error) {
    return handleFirebaseServiceError("Error fetching settings:", error);
  }
}

// PUT update settings
export async function PUT(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json({
      data: await updateSettingsData((await request.json()) as Record<string, unknown>),
    });
  } catch (error) {
    return handleFirebaseServiceError("Error updating settings:", error);
  }
}
