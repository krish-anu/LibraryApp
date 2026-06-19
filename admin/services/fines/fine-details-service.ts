import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError } from "@/lib/server-api";

// GET single fine
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json(
      { error: `Fine ${id} is not migrated to PostgreSQL yet.` },
      { status: 501 },
    );
  } catch (error) {
    return handleLibraryApiError("Error fetching fine:", error);
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
      { error: `Fine ${id} is not migrated to PostgreSQL yet.` },
      { status: 501 },
    );
  } catch (error) {
    return handleLibraryApiError("Error updating fine:", error);
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
    return NextResponse.json(
      { error: `Fine ${id} is not migrated to PostgreSQL yet.` },
      { status: 501 },
    );
  } catch (error) {
    return handleLibraryApiError("Error deleting fine:", error);
  }
}
