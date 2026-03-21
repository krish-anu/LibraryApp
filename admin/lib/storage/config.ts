export type StorageConfig = {
  region: string;
  endpointBase: string;
  s3Endpoint: string;
  bucket: string;
  accessKeyId: string;
  secretAccessKey: string;
};

function sanitizeEnvValue(value?: string | null): string {
  if (!value) {
    return "";
  }

  const trimmed = value.trim();
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1).trim();
  }

  return trimmed;
}

export function resolveStorageConfig(): StorageConfig {
  const region = sanitizeEnvValue(process.env.S3_REGION) || "ap-south-1";
  const rawEndpoint = sanitizeEnvValue(process.env.S3_ENDPOINT);
  const endpointBase = rawEndpoint
    .replace(/\/+$/, "")
    .replace(/\/storage\/v1\/s3$/, "");

  return {
    region,
    endpointBase,
    s3Endpoint: endpointBase ? `${endpointBase}/storage/v1/s3` : "",
    bucket:
      sanitizeEnvValue(process.env.S3_BUCKET) ||
      sanitizeEnvValue(process.env.SUPABASE_STORAGE_BUCKET),
    accessKeyId: sanitizeEnvValue(process.env.S3_ACCESS_KEY_ID),
    secretAccessKey: sanitizeEnvValue(process.env.S3_SECRET_ACCESS_KEY),
  };
}

export function getStorageConfigErrors(config: StorageConfig): string[] {
  const errors: string[] = [];

  if (!config.s3Endpoint) {
    errors.push("S3 endpoint not configured: set S3_ENDPOINT");
  }
  if (!config.bucket) {
    errors.push(
      "S3 bucket not configured: set S3_BUCKET or SUPABASE_STORAGE_BUCKET",
    );
  }
  if (!config.accessKeyId || !config.secretAccessKey) {
    errors.push(
      "S3 credentials not configured: set S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY",
    );
  }

  return errors;
}

export function buildPublicObjectUrl(
  config: StorageConfig,
  key: string,
): string {
  const encodedKey = key.split("/").map(encodeURIComponent).join("/");
  return `${config.endpointBase}/storage/v1/object/public/${config.bucket}/${encodedKey}`;
}
