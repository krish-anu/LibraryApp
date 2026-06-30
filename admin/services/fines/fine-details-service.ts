import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

async function finePath(params: Promise<{ id: string }>) {
  const { id } = await params;
  return `/fines/${encodeURIComponent(id)}`;
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(await libraryApi(request, await finePath(params)));
  } catch (error) {
    return handleLibraryApiError("Error fetching fine:", error);
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(
      await libraryApi(request, await finePath(params), {
        method: "PUT",
        body: JSON.stringify(await request.json()),
      }),
    );
  } catch (error) {
    return handleLibraryApiError("Error updating fine:", error);
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(
      await libraryApi(request, await finePath(params), { method: "DELETE" }),
    );
  } catch (error) {
    return handleLibraryApiError("Error deleting fine:", error);
  }
}
