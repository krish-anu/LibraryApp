import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  deleteBookData,
  getBookData,
  updateBookData,
} from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

// GET single book
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    return NextResponse.json({ data: await getBookData(id) });
  } catch (error) {
    return handleFirebaseServiceError("Error fetching book:", error);
  }
}

// PUT update book
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json({
      data: await updateBookData(id, (await request.json()) as Record<string, unknown>),
    });
  } catch (error) {
    return handleFirebaseServiceError("Error updating book:", error);
  }
}

// DELETE book
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json(await deleteBookData(id));
  } catch (error) {
    return handleFirebaseServiceError("Error deleting book:", error);
  }
}
