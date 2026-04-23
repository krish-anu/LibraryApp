import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { uploadBufferToFirebaseStorage } from "@/lib/firebase/storage";

export const runtime = "nodejs";

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "image/svg+xml",
]);
const ALLOWED_EXTENSIONS = new Set([
  ".jpg",
  ".jpeg",
  ".png",
  ".webp",
  ".gif",
  ".svg",
]);

export async function POST(req: NextRequest) {
  const auth = await verifyAdmin(req);
  if (auth.error) return auth.error;

  try {
    const contentType = req.headers.get("content-type") || "";
    if (!contentType.toLowerCase().includes("multipart/form-data")) {
      return NextResponse.json(
        {
          error:
            "invalid content-type: expected multipart/form-data with a file field",
          receivedContentType: contentType || null,
        },
        { status: 415 },
      );
    }

    const form = await req.formData();
    const file = form.get("file") as File | null;
    if (!file)
      return NextResponse.json({ error: "missing file" }, { status: 400 });

    // Validate file size
    if (file.size > MAX_FILE_SIZE) {
      return NextResponse.json(
        {
          error: `File too large. Maximum size is ${MAX_FILE_SIZE / (1024 * 1024)}MB`,
        },
        { status: 413 },
      );
    }

    // Validate MIME type
    const mimeType = (file.type || "").toLowerCase();
    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      return NextResponse.json(
        {
          error: `File type '${mimeType}' not allowed. Allowed types: ${[...ALLOWED_MIME_TYPES].join(", ")}`,
        },
        { status: 415 },
      );
    }

    // Validate file extension
    const ext = (file.name || "").toLowerCase().match(/\.[^.]+$/)?.[0] || "";
    if (!ALLOWED_EXTENSIONS.has(ext)) {
      return NextResponse.json(
        {
          error: `File extension '${ext}' not allowed. Allowed: ${[...ALLOWED_EXTENSIONS].join(", ")}`,
        },
        { status: 415 },
      );
    }

    const filename = (form.get("filename") as string) || file.name || "upload";
    const safeName = filename.replace(/[^a-zA-Z0-9.-_]/g, "_");
    const key = `books/${Date.now()}-${Math.random().toString(36).slice(2)}-${safeName}`;

    // Basic env checks for clearer diagnostics
    console.log(`/api/storage/upload starting upload`, {
      key,
      filename,
      contentType: file.type,
      size: file.size,
    });
    const arrayBuffer = await file.arrayBuffer();
    const body = Buffer.from(arrayBuffer);
    const { publicUrl } = await uploadBufferToFirebaseStorage({
      key,
      body,
      contentType: file.type || "application/octet-stream",
    });

    return NextResponse.json({ publicUrl, key }, { status: 201 });
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    const errorStack = err instanceof Error ? err.stack : undefined;
    console.error("/api/storage/upload error:", errorStack || errorMessage);
    return NextResponse.json({ error: errorMessage }, { status: 500 });
  }
}
