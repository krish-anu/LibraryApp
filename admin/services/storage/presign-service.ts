import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { createFirebaseSignedUploadUrls } from "@/lib/firebase/storage";

const ALLOWED_CONTENT_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
]);

export async function POST(req: NextRequest) {
  const auth = await verifyAdmin(req);
  if (auth.error) return auth.error;

  try {
    const body = await req.json();
    const { key, contentType } = body;
    if (!key || !contentType) {
      return NextResponse.json(
        { error: "missing key or contentType" },
        { status: 400 },
      );
    }

    // Validate content type
    if (!ALLOWED_CONTENT_TYPES.has(contentType.toLowerCase())) {
      return NextResponse.json(
        {
          error: `Content type '${contentType}' not allowed. Allowed: ${[...ALLOWED_CONTENT_TYPES].join(", ")}`,
        },
        { status: 415 },
      );
    }

    // Validate key is within allowed path prefix
    if (!key.startsWith("books/")) {
      return NextResponse.json(
        { error: "Key must start with 'books/' prefix" },
        { status: 400 },
      );
    }

    // Prevent path traversal
    if (key.includes("..") || key.includes("//")) {
      return NextResponse.json({ error: "Invalid key path" }, { status: 400 });
    }
    const signedUrls = await createFirebaseSignedUploadUrls({
      key,
      contentType,
      expiresInSeconds: 3600,
    });

    return NextResponse.json(signedUrls);
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    console.error("/api/storage/presign error:", errorMessage);
    return NextResponse.json({ error: errorMessage }, { status: 500 });
  }
}
