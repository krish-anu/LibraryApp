import crypto from "crypto";

/**
 * Generate a cryptographically random code_verifier (43-128 chars, URL-safe).
 */
export function generateCodeVerifier(length = 64): string {
  return crypto.randomBytes(length).toString("base64url").slice(0, 128);
}

/**
 * Derive the code_challenge from a code_verifier using SHA-256 (S256).
 */
export function generateCodeChallenge(codeVerifier: string): string {
  return crypto.createHash("sha256").update(codeVerifier).digest("base64url");
}

/**
 * Generate a random string suitable for the OAuth2 `state` parameter.
 */
export function generateState(): string {
  return crypto.randomBytes(32).toString("base64url");
}
