import { cert, getApps, initializeApp, type App } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

type FirebaseAdminConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
  storageBucket: string;
};

type FirebaseServiceAccountJson = {
  project_id?: string;
  client_email?: string;
  private_key?: string;
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

function parseServiceAccountJson(
  rawValue: string,
): FirebaseServiceAccountJson | null {
  if (!rawValue) {
    return null;
  }

  try {
    return JSON.parse(rawValue) as FirebaseServiceAccountJson;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(
      `Invalid FIREBASE_SERVICE_ACCOUNT_JSON value: ${message}`,
    );
  }
}

function resolveFirebaseAdminConfig(): FirebaseAdminConfig {
  const serviceAccount = parseServiceAccountJson(
    sanitizeEnvValue(process.env.FIREBASE_SERVICE_ACCOUNT_JSON),
  );

  const projectId =
    sanitizeEnvValue(process.env.FIREBASE_PROJECT_ID) ||
    serviceAccount?.project_id ||
    "";
  const clientEmail =
    sanitizeEnvValue(process.env.FIREBASE_CLIENT_EMAIL) ||
    serviceAccount?.client_email ||
    "";
  const privateKey =
    (
      sanitizeEnvValue(process.env.FIREBASE_PRIVATE_KEY) ||
      serviceAccount?.private_key ||
      ""
    ).replace(/\\n/g, "\n");
  const storageBucket = sanitizeEnvValue(process.env.FIREBASE_STORAGE_BUCKET);

  const missing: string[] = [];
  if (!projectId) missing.push("FIREBASE_PROJECT_ID");
  if (!clientEmail) missing.push("FIREBASE_CLIENT_EMAIL");
  if (!privateKey) missing.push("FIREBASE_PRIVATE_KEY");
  if (!storageBucket) missing.push("FIREBASE_STORAGE_BUCKET");

  if (missing.length > 0) {
    throw new Error(
      `Firebase Admin configuration is incomplete. Set ${missing.join(", ")} or provide FIREBASE_SERVICE_ACCOUNT_JSON plus FIREBASE_STORAGE_BUCKET.`,
    );
  }

  return {
    projectId,
    clientEmail,
    privateKey,
    storageBucket,
  };
}

export function getFirebaseAdminApp(): App {
  const existingApp = getApps()[0];
  if (existingApp) {
    return existingApp;
  }

  const config = resolveFirebaseAdminConfig();

  return initializeApp({
    credential: cert({
      projectId: config.projectId,
      clientEmail: config.clientEmail,
      privateKey: config.privateKey,
    }),
    storageBucket: config.storageBucket,
  });
}

export function getFirebaseStorageBucketName(): string {
  return resolveFirebaseAdminConfig().storageBucket;
}

export function getFirebaseStorageBucket() {
  return getStorage(getFirebaseAdminApp()).bucket(
    getFirebaseStorageBucketName(),
  );
}

export function getFirebaseFirestore() {
  return getFirestore(getFirebaseAdminApp());
}
