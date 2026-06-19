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
]);
const ALLOWED_EXTENSIONS = new Set([".jpg", ".jpeg", ".png", ".webp", ".gif"]);

function hasAllowedMagicBytes(body: Buffer, mimeType: string) {
  if (mimeType === "image/jpeg") {
    return body.length >= 3 && body[0] === 0xff && body[1] === 0xd8 && body[2] === 0xff;
  }
  if (mimeType === "image/png") {
    return (
      body.length >= 8 &&
      body[0] === 0x89 &&
      body[1] === 0x50 &&
      body[2] === 0x4e &&
      body[3] === 0x47 &&
      body[4] === 0x0d &&
      body[5] === 0x0a &&
      body[6] === 0x1a &&
      body[7] === 0x0a
    );
  }
  if (mimeType === "image/gif") {
    return body.length >= 4 && body.subarray(0, 4).toString("ascii") === "GIF8";
  }
  if (mimeType === "image/webp") {
    return (
      body.length >= 12 &&
      body.subarray(0, 4).toString("ascii") === "RIFF" &&
      body.subarray(8, 12).toString("ascii") === "WEBP"
    );
  }
  return false;
}

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
      contentType: file.type,
      size: file.size,
    });
    const arrayBuffer = await file.arrayBuffer();
    const body = Buffer.from(arrayBuffer);
    if (!hasAllowedMagicBytes(body, mimeType)) {
      return NextResponse.json(
        { error: "File contents do not match an allowed image type" },
        { status: 415 },
      );
    }

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
