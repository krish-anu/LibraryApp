import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  deleteUserData,
  getUserWithStatsData,
  updateUserData,
} from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

// GET single user with stats
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json({ data: await getUserWithStatsData(id) });
  } catch (error) {
    return handleFirebaseServiceError("Error fetching user:", error);
  }
}

// PUT update user
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json({
      data: await updateUserData(id, (await request.json()) as Record<string, unknown>),
    });
  } catch (error) {
    return handleFirebaseServiceError("Error updating user:", error);
  }
}

// DELETE user
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json(await deleteUserData(id));
  } catch (error) {
    return handleFirebaseServiceError("Error deleting user:", error);
  }
}
