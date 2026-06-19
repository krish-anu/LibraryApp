import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

// GET single user with stats
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json({
      data: await libraryApi(request, `/users/${id}/stats`),
    });
  } catch (error) {
    return handleLibraryApiError("Error fetching user:", error);
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
    return NextResponse.json(
      { error: "Updating users is not migrated to PostgreSQL yet." },
      { status: 501 },
    );
  } catch (error) {
    return handleLibraryApiError("Error updating user:", error);
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
    return NextResponse.json(
      { error: "Deleting users is not migrated to PostgreSQL yet." },
      { status: 501 },
    );
  } catch (error) {
    return handleLibraryApiError("Error deleting user:", error);
  }
}
