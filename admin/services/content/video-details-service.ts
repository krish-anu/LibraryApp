import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";
import type { VideoPost } from "@/lib/types";
import { normalizeVideo, videoPayload } from "./content-utils";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    const video = await libraryApi<VideoPost>(
      request,
      `/videos/${encodeURIComponent(id)}?include_unpublished=true`,
    );
    return NextResponse.json({ data: normalizeVideo(video) });
  } catch (error) {
    return handleLibraryApiError("Error fetching video:", error);
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    const updatedVideo = await libraryApi<VideoPost>(
      request,
      `/videos/${encodeURIComponent(id)}`,
      {
        method: "PUT",
        body: JSON.stringify(videoPayload((await request.json()) as Record<string, unknown>)),
      },
    );
    return NextResponse.json({ data: normalizeVideo(updatedVideo) });
  } catch (error) {
    return handleLibraryApiError("Error updating video:", error);
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    await libraryApi<void>(request, `/videos/${encodeURIComponent(id)}`, {
      method: "DELETE",
    });
    return NextResponse.json({ success: true });
  } catch (error) {
    return handleLibraryApiError("Error deleting video:", error);
  }
}
