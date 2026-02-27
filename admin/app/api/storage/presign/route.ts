import { NextRequest, NextResponse } from "next/server";
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const region = process.env.S3_REGION || "ap-south-1";
const rawEndpoint =
  process.env.S3_ENDPOINT || "https://gdervtvlkioxsobrwaqm.storage.supabase.co";
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
  try {
    const body = await req.json();
    const { key, contentType } = body;
    if (!key || !contentType) {
      return NextResponse.json(
        { error: "missing key or contentType" },
        { status: 400 },
      );
    }
    if (!bucket) {
      return NextResponse.json(
        { error: "missing S3_BUCKET or SUPABASE_STORAGE_BUCKET in server env" },
        { status: 500 },
      );
    }

    const client = getClient();

    const putCmd = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: contentType,
    });
    const putUrl = await getSignedUrl(client, putCmd, { expiresIn: 3600 });

    // Signed GET URL (optional) so client can fetch after upload
    const getCmd = new GetObjectCommand({ Bucket: bucket, Key: key });
    const getUrl = await getSignedUrl(client, getCmd, { expiresIn: 3600 });

    // Public object URL (works if bucket/object is public via Supabase storage)
    const encodedKey = key.split("/").map(encodeURIComponent).join("/");
    const publicUrl = `${endpointBase}/storage/v1/object/public/${bucket}/${encodedKey}`;

    return NextResponse.json({ putUrl, getUrl, publicUrl });
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    console.error("/api/storage/presign error:", errorMessage);
    return NextResponse.json(
      { error: errorMessage },
      { status: 500 },
    );
  }
}
