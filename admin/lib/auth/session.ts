import { sanitizeEnvValue } from "@/lib/auth/env";
import type { VerifiedUser } from "@/lib/auth/user-info";

const encoder = new TextEncoder();
const SESSION_CLOCK_SKEW_SECONDS = 30;

export type AdminSessionMeta = {
  iat: number;
  exp: number;
};

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

function signaturePayload(
  accessToken: string,
  userPayload: string,
  metaPayload: string,
) {
  return `${accessToken}.${userPayload}.${metaPayload}`;
}

function parsePositiveInteger(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value <= 0) {
    return null;
  }
  return value;
}

function readJsonCandidates(payload: string): unknown[] {
  const candidates = [payload];
  try {
    const decoded = decodeURIComponent(payload);
    if (decoded !== payload) {
      candidates.push(decoded);
    }
  } catch {
    // Already decoded.
  }

  return candidates.flatMap((candidate) => {
    try {
      return [JSON.parse(candidate)];
    } catch {
      return [];
    }
  });
}

export function createAdminSessionMeta(expiresIn: number): string {
  const now = Math.floor(Date.now() / 1000);
  const ttl = Number.isFinite(expiresIn) && expiresIn > 0 ? expiresIn : 3600;
  return JSON.stringify({
    iat: now,
    exp: now + Math.floor(ttl),
  } satisfies AdminSessionMeta);
}

export function readSessionMeta(metaPayload: string): AdminSessionMeta | null {
  if (!metaPayload) {
    return null;
  }

  for (const parsed of readJsonCandidates(metaPayload)) {
    if (!parsed || typeof parsed !== "object") {
      continue;
    }
    const record = parsed as Partial<AdminSessionMeta>;
    const iat = parsePositiveInteger(record.iat);
    const exp = parsePositiveInteger(record.exp);
    if (iat && exp && exp > iat) {
      return { iat, exp };
    }
  }

  return null;
}

export function sessionMetaIsCurrent(meta: AdminSessionMeta | null) {
  if (!meta) {
    return false;
  }

  const now = Math.floor(Date.now() / 1000);
  if (meta.iat > now + SESSION_CLOCK_SKEW_SECONDS) {
    return false;
  }
  return meta.exp > now - SESSION_CLOCK_SKEW_SECONDS;
}

export async function signAdminSession(
  accessToken: string,
  userPayload: string,
  metaPayload: string,
) {
  return hmac(signaturePayload(accessToken, userPayload, metaPayload));
}

export async function verifyAdminSession(
  accessToken: string,
  userPayload: string,
  metaPayload: string,
  signature: string,
) {
  if (!accessToken || !userPayload || !metaPayload || !signature) {
    return false;
  }

  if (!sessionMetaIsCurrent(readSessionMeta(metaPayload))) {
    return false;
  }

  const userCandidates = [userPayload];
  const metaCandidates = [metaPayload];
  try {
    const decodedUser = decodeURIComponent(userPayload);
    if (decodedUser !== userPayload) {
      userCandidates.push(decodedUser);
    }
  } catch {
    // Already decoded.
  }
  try {
    const decodedMeta = decodeURIComponent(metaPayload);
    if (decodedMeta !== metaPayload) {
      metaCandidates.push(decodedMeta);
    }
  } catch {
    // Already decoded.
  }

  for (const userCandidate of userCandidates) {
    for (const metaCandidate of metaCandidates) {
      const expected = await signAdminSession(
        accessToken,
        userCandidate,
        metaCandidate,
      );
      if (expected && expected === signature) {
        return true;
      }
    }
  }

  return false;
}

export function readSessionUser(userPayload: string): VerifiedUser | null {
  if (!userPayload) {
    return null;
  }

  for (const parsed of readJsonCandidates(userPayload)) {
    if (!parsed || typeof parsed !== "object") {
      continue;
    }
    const user = parsed as Partial<VerifiedUser>;
    const sub = typeof user.sub === "string" ? user.sub.trim() : "";
    if (!sub) {
      continue;
    }
    return {
      sub,
      email: typeof user.email === "string" ? user.email : "",
      name: typeof user.name === "string" ? user.name : "",
    };
  }

  return null;
}
