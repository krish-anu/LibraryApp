import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { createStorageClient } from "@/lib/storage/client";
import {
  buildPublicObjectUrl,
  getStorageConfigErrors,
  resolveStorageConfig,
} from "@/lib/storage/config";
import { PutObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const ALLOWED_CONTENT_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "image/svg+xml",
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
    const storageConfig = resolveStorageConfig();
    const storageErrors = getStorageConfigErrors(storageConfig);
    if (storageErrors.length > 0) {
      return NextResponse.json({ error: storageErrors[0] }, { status: 500 });
    }

    const client = createStorageClient(storageConfig);

    const putCmd = new PutObjectCommand({
      Bucket: storageConfig.bucket,
      Key: key,
      ContentType: contentType,
    });
    const putUrl = await getSignedUrl(client, putCmd, { expiresIn: 3600 });

    // Signed GET URL (optional) so client can fetch after upload
    const getCmd = new GetObjectCommand({
      Bucket: storageConfig.bucket,
      Key: key,
    });
    const getUrl = await getSignedUrl(client, getCmd, { expiresIn: 3600 });

    const publicUrl = buildPublicObjectUrl(storageConfig, key);

    return NextResponse.json({ putUrl, getUrl, publicUrl });
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    console.error("/api/storage/presign error:", errorMessage);
    return NextResponse.json({ error: errorMessage }, { status: 500 });
  }
}
