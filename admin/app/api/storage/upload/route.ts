import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import {
  S3Client,
  PutObjectCommand,
  ListBucketsCommand,
} from "@aws-sdk/client-s3";

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
  ".jpg", ".jpeg", ".png", ".webp", ".gif", ".svg",
]);

const region = process.env.S3_REGION || "ap-south-1";
const rawEndpoint =
  process.env.S3_ENDPOINT || "";
const bucket =
  process.env.S3_BUCKET || process.env.SUPABASE_STORAGE_BUCKET || "";
const endpointBase = rawEndpoint.replace(/\/+$/, "").replace(/\/storage\/v1\/s3$/, "");
const s3Endpoint = `${endpointBase}/storage/v1/s3`;

function getClient() {
  const accessKeyId = process.env.S3_ACCESS_KEY_ID || "";
  const secretAccessKey = process.env.S3_SECRET_ACCESS_KEY || "";
  return new S3Client({
    region,
    endpoint: s3Endpoint,
    credentials: { accessKeyId, secretAccessKey },
    forcePathStyle: true,
  });
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
        { error: `File too large. Maximum size is ${MAX_FILE_SIZE / (1024 * 1024)}MB` },
        { status: 413 },
      );
    }

    // Validate MIME type
    const mimeType = (file.type || "").toLowerCase();
    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      return NextResponse.json(
        { error: `File type '${mimeType}' not allowed. Allowed types: ${[...ALLOWED_MIME_TYPES].join(", ")}` },
        { status: 415 },
      );
    }

    // Validate file extension
    const ext = (file.name || "").toLowerCase().match(/\.[^.]+$/)?.[0] || "";
    if (!ALLOWED_EXTENSIONS.has(ext)) {
      return NextResponse.json(
        { error: `File extension '${ext}' not allowed. Allowed: ${[...ALLOWED_EXTENSIONS].join(", ")}` },
        { status: 415 },
      );
    }

    const filename = (form.get("filename") as string) || file.name || "upload";
    const safeName = filename.replace(/[^a-zA-Z0-9.-_]/g, "_");
    const key = `books/${Date.now()}-${Math.random().toString(36).slice(2)}-${safeName}`;

    const client = getClient();

    // Basic env checks for clearer diagnostics
    const accessKeyId = process.env.S3_ACCESS_KEY_ID || "";
    const secretAccessKey = process.env.S3_SECRET_ACCESS_KEY || "";
    if (!accessKeyId || !secretAccessKey) {
      console.error(
        "S3 credentials not configured: S3_ACCESS_KEY_ID or S3_SECRET_ACCESS_KEY missing",
      );
      return NextResponse.json(
        { error: "S3 credentials not configured on server" },
        { status: 500 },
      );
    }
    if (!bucket) {
      console.error(
        "S3 bucket not configured: set S3_BUCKET or SUPABASE_STORAGE_BUCKET",
      );
      return NextResponse.json(
        { error: "S3 bucket not configured on server" },
        { status: 500 },
      );
    }

    console.log(`/api/storage/upload starting upload`, {
      key,
      filename,
      contentType: file.type,
      size: file.size,
    });
    const arrayBuffer = await file.arrayBuffer();
    const body = Buffer.from(arrayBuffer);

    const putCmd = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: body,
      ContentType: file.type || "application/octet-stream",
    });

    // Helper to read raw response body from AWS SDK errors (if present)
    async function streamToString(stream: unknown) {
      if (!stream) return "";
      if (typeof stream !== "object") return String(stream);
      if ("arrayBuffer" in stream && typeof stream.arrayBuffer === "function") {
        const ab = await stream.arrayBuffer();
        return Buffer.from(ab).toString("utf8");
      }
      if (Symbol.asyncIterator in stream) {
        const chunks: string[] = [];
        const asyncIterable = stream as AsyncIterable<Uint8Array | string>;
        for await (const chunk of asyncIterable) {
          chunks.push(
            typeof chunk === "string"
              ? chunk
              : Buffer.from(chunk).toString("utf8"),
          );
        }
        return chunks.join("");
      }
      try {
        return String(stream);
      } catch {
        return "";
      }
    }

    let resp;
    try {
      resp = await client.send(putCmd);
      console.log("PutObject response metadata:", resp?.$metadata || resp);
    } catch (error: unknown) {
      const err = error as {
        name?: string;
        message?: string;
        $response?: { body?: unknown };
      };
      console.error("PutObject failed:", err.name || err.message || err);
      let raw = "";
      try {
        raw = await streamToString(err.$response?.body);
      } catch (readErr) {
        console.error("Failed to read error body:", readErr);
      }
      console.error("Raw error body:", raw);

      let availableBuckets: string[] | undefined;
      if (err.name === "NoSuchBucket" || err.message === "Bucket not found") {
        try {
          const listed = await client.send(new ListBucketsCommand({}));
          availableBuckets = (listed?.Buckets || [])
            .map((b) => b.Name)
            .filter((name): name is string => Boolean(name));
        } catch (listErr: unknown) {
          const listErrMessage =
            listErr instanceof Error ? listErr.message : String(listErr);
          console.error(
            "Failed to list buckets for diagnostics:",
            listErrMessage,
          );
        }
      }

      return NextResponse.json(
        {
          error: "Failed to upload file to storage. Please try again.",
        },
        { status: 500 },
      );
    }

    const encodedKey = key.split("/").map(encodeURIComponent).join("/");
    const publicUrl = `${endpointBase}/storage/v1/object/public/${bucket}/${encodedKey}`;

    return NextResponse.json({ publicUrl, key }, { status: 201 });
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    const errorStack = err instanceof Error ? err.stack : undefined;
    console.error(
      "/api/storage/upload error:",
      errorStack || errorMessage,
    );
    return NextResponse.json(
      { error: errorMessage },
      { status: 500 },
    );
  }
}
