import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  deleteFineData,
  getFineData,
  updateFineData,
} from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

// GET single fine
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json({ data: await getFineData(id) });
  } catch (error) {
    return handleFirebaseServiceError("Error fetching fine:", error);
  }
}

// PUT update fine
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json(
      await updateFineData(id, (await request.json()) as Record<string, unknown>),
    );
  } catch (error) {
    return handleFirebaseServiceError("Error updating fine:", error);
  }
}

// DELETE fine
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json(await deleteFineData(id));
  } catch (error) {
    return handleFirebaseServiceError("Error deleting fine:", error);
  }
}
