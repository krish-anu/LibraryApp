import { sanitizeEnvValue } from "@/lib/auth/env";
import type { VerifiedUser } from "@/lib/auth/user-info";

const encoder = new TextEncoder();

function sessionSecret() {
  return (
    sanitizeEnvValue(process.env.ADMIN_SESSION_SECRET) ||
    sanitizeEnvValue(process.env.ASGARDEO_CLIENT_SECRET)
  );
}

function base64Url(bytes: ArrayBuffer) {
  const binary = String.fromCharCode(...new Uint8Array(bytes));
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

async function hmac(data: string) {
  const secret = sessionSecret();
  if (!secret || !globalThis.crypto?.subtle) {
    return "";
  }

  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(data));
  return base64Url(signature);
}

function signaturePayload(accessToken: string, userPayload: string) {
  return `${accessToken}.${userPayload}`;
}

export async function signAdminSession(
  accessToken: string,
  userPayload: string,
) {
  return hmac(signaturePayload(accessToken, userPayload));
}

export async function verifyAdminSession(
  accessToken: string,
  userPayload: string,
  signature: string,
) {
  if (!accessToken || !userPayload || !signature) {
    return false;
  }

  const candidates = [userPayload];
  try {
    const decoded = decodeURIComponent(userPayload);
    if (decoded !== userPayload) {
      candidates.push(decoded);
    }
  } catch {
    // Already decoded.
  }

  for (const candidate of candidates) {
    const expected = await signAdminSession(accessToken, candidate);
    if (expected && expected === signature) {
      return true;
    }
  }

  return false;
}

export function readSessionUser(userPayload: string): VerifiedUser | null {
  if (!userPayload) {
    return null;
  }

  const candidates = [userPayload];
  try {
    candidates.push(decodeURIComponent(userPayload));
  } catch {
    // Already decoded.
  }

  for (const candidate of candidates) {
    try {
      const parsed = JSON.parse(candidate) as Partial<VerifiedUser>;
      const sub = typeof parsed.sub === "string" ? parsed.sub.trim() : "";
      if (!sub) {
        continue;
      }
      return {
        sub,
        email: typeof parsed.email === "string" ? parsed.email : "",
        name: typeof parsed.name === "string" ? parsed.name : "",
      };
    } catch {
      // Try the next representation.
    }
  }

  return null;
}
