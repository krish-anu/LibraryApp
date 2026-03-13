import type { NextRequest } from "next/server";

export function sanitizeEnvValue(value?: string | null): string {
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

export function resolveAppUrl(request?: NextRequest): string {
  const configuredUrl = sanitizeEnvValue(process.env.NEXT_PUBLIC_APP_URL);
  return request?.nextUrl.origin || configuredUrl || "http://localhost:3000";
}
