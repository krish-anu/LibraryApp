import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  handleLibraryApiError,
  libraryApi,
  libraryApiUrl,
} from "@/lib/server-api";

export const runtime = "nodejs";

const MAX_FILE_SIZE = 10 * 1024 * 1024;
const ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
]);

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    const response = await fetch(
      libraryApiUrl(`/books/${encodeURIComponent(id)}/image`),
      { cache: "no-store" },
    );

    if (!response.ok) {
      const body = await response.text().catch(() => "");
      return new NextResponse(body || "Book image not found", {
        status: response.status,
        headers: {
          "Content-Type":
            response.headers.get("content-type") || "text/plain; charset=utf-8",
        },
      });
    }

    return new NextResponse(response.body, {
      status: response.status,
      headers: {
        "Content-Type":
          response.headers.get("content-type") || "application/octet-stream",
        "Cache-Control":
          response.headers.get("cache-control") || "public, max-age=3600",
      },
    });
  } catch (error) {
    return handleLibraryApiError("Error fetching book image:", error);
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const contentType = request.headers.get("content-type") || "";
    if (!contentType.toLowerCase().includes("multipart/form-data")) {
      return NextResponse.json(
        { error: "Expected multipart/form-data with a file field" },
        { status: 415 },
      );
    }

    const form = await request.formData();
    const file = form.get("file") as File | null;
    if (!file) {
      return NextResponse.json({ error: "missing file" }, { status: 400 });
    }
    if (file.size > MAX_FILE_SIZE) {
      return NextResponse.json({ error: "File too large" }, { status: 413 });
    }
    if (!ALLOWED_MIME_TYPES.has(file.type)) {
      return NextResponse.json({ error: "Unsupported image type" }, { status: 415 });
    }

    const { id } = await params;
    const body = Buffer.from(await file.arrayBuffer());
    const updatedBook = await libraryApi(request, `/books/${encodeURIComponent(id)}/image`, {
      method: "PUT",
      headers: { "Content-Type": file.type },
      body,
    });

    return NextResponse.json({ data: updatedBook });
  } catch (error) {
    return handleLibraryApiError("Error uploading book image:", error);
  }
}
