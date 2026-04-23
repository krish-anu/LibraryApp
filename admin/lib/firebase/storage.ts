import { randomUUID } from "node:crypto";
import {
  getFirebaseStorageBucket,
  getFirebaseStorageBucketName,
} from "./admin";

export type FirebaseSignedUploadUrls = {
  putUrl: string;
  getUrl: string;
  publicUrl: string;
  uploadHeaders: Record<string, string>;
};

function encodeStorageObjectPath(path: string): string {
  return encodeURIComponent(path);
}

export function buildFirebaseDownloadUrl(
  bucketName: string,
  path: string,
  downloadToken: string,
): string {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeStorageObjectPath(path)}?alt=media&token=${downloadToken}`;
}

export async function uploadBufferToFirebaseStorage(options: {
  key: string;
  body: Buffer;
  contentType: string;
}): Promise<{ key: string; publicUrl: string }> {
  const bucket = getFirebaseStorageBucket();
  const downloadToken = randomUUID();

  await bucket.file(options.key).save(options.body, {
    resumable: false,
    metadata: {
      contentType: options.contentType,
      metadata: {
        firebaseStorageDownloadTokens: downloadToken,
      },
    },
  });

  return {
    key: options.key,
    publicUrl: buildFirebaseDownloadUrl(
      bucket.name,
      options.key,
      downloadToken,
    ),
  };
}

export async function createFirebaseSignedUploadUrls(options: {
  key: string;
  contentType: string;
  expiresInSeconds?: number;
}): Promise<FirebaseSignedUploadUrls> {
  const bucket = getFirebaseStorageBucket();
  const bucketName = getFirebaseStorageBucketName();
  const downloadToken = randomUUID();
  const expiresAt = Date.now() + (options.expiresInSeconds ?? 3600) * 1000;
  const file = bucket.file(options.key);

  const uploadHeaders = {
    "Content-Type": options.contentType,
    "x-goog-meta-firebaseStorageDownloadTokens": downloadToken,
  };

  const [putUrl] = await file.getSignedUrl({
    action: "write",
    version: "v4",
    expires: expiresAt,
    contentType: options.contentType,
    extensionHeaders: {
      "x-goog-meta-firebaseStorageDownloadTokens": downloadToken,
    },
  });

  const [getUrl] = await file.getSignedUrl({
    action: "read",
    version: "v4",
    expires: expiresAt,
  });

  return {
    putUrl,
    getUrl,
    publicUrl: buildFirebaseDownloadUrl(
      bucketName,
      options.key,
      downloadToken,
    ),
    uploadHeaders,
  };
}
