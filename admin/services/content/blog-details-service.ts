import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";
import type { BlogPost } from "@/lib/types";
import { blogPayload, normalizeBlog } from "./content-utils";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    const blog = await libraryApi<BlogPost>(
      request,
      `/blogs/${encodeURIComponent(id)}?include_unpublished=true`,
    );
    return NextResponse.json({ data: normalizeBlog(blog) });
  } catch (error) {
    return handleLibraryApiError("Error fetching blog:", error);
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
    const updatedBlog = await libraryApi<BlogPost>(
      request,
      `/blogs/${encodeURIComponent(id)}`,
      {
        method: "PUT",
        body: JSON.stringify(blogPayload((await request.json()) as Record<string, unknown>)),
      },
    );
    return NextResponse.json({ data: normalizeBlog(updatedBlog) });
  } catch (error) {
    return handleLibraryApiError("Error updating blog:", error);
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
    await libraryApi<void>(request, `/blogs/${encodeURIComponent(id)}`, {
      method: "DELETE",
    });
    return NextResponse.json({ success: true });
  } catch (error) {
    return handleLibraryApiError("Error deleting blog:", error);
  }
}
