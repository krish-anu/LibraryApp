import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Paths that don't require authentication
const PUBLIC_PATHS = [
  "/login",
  "/api/auth/login",
  "/api/auth/callback",
  "/api/auth/callback/asgardeo",
  "/api/auth/logout",
  "/api/auth/me",
];

const COOKIE_CLEAR_OPTIONS = { path: "/", maxAge: 0 };

function unauthorized(request: NextRequest) {
  const { pathname } = request.nextUrl;
  if (pathname.startsWith("/api/")) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const loginUrl = new URL("/login", request.url);
  const response = NextResponse.redirect(loginUrl);
  response.cookies.set("library_session", "", COOKIE_CLEAR_OPTIONS);
  response.cookies.set("library_id_token", "", COOKIE_CLEAR_OPTIONS);
  response.cookies.set("library_user", "", COOKIE_CLEAR_OPTIONS);
  return response;
}

function csvEnv(name: string, fallback = "") {
  return new Set(
    (process.env[name] || fallback)
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean),
  );
}

function claimValues(value: unknown): Set<string> {
  const values = new Set<string>();
  if (typeof value === "string") {
    value
      .replaceAll(",", " ")
      .split(/\s+/)
      .map((part) => part.trim().toLowerCase())
      .filter(Boolean)
      .forEach((part) => values.add(part));
    return values;
  }
  if (Array.isArray(value)) {
    value.forEach((entry) => {
      claimValues(entry).forEach((part) => values.add(part));
    });
    return values;
  }
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    ["value", "name", "display", "displayName"].forEach((key) => {
      const item = record[key];
      if (typeof item === "string" && item.trim()) {
        values.add(item.trim().toLowerCase());
      }
    });
  }
  return values;
}

function isAdminUser(info: Record<string, unknown>) {
  const email = typeof info.email === "string" ? info.email.toLowerCase() : "";
  const allowedEmails = csvEnv("ADMIN_EMAILS");
  if (email && allowedEmails.has(email)) {
    return true;
  }

  const allowedGroups = csvEnv(
    "ADMIN_GROUPS",
    "admin,library-admin,library_admin,Library Administrator",
  );
  const claims = new Set<string>();
  ["groups", "roles", "role", "permissions", "scope"].forEach((claim) => {
    claimValues(info[claim]).forEach((value) => claims.add(value));
  });
  return [...claims].some((claim) => allowedGroups.has(claim));
}

async function validateAdminWithUserInfo(accessToken: string): Promise<boolean> {
  const userInfoEndpoint = (process.env.ASGARDEO_USERINFO_ENDPOINT || "").trim();
  if (!userInfoEndpoint) {
    return false;
  }

  try {
    const res = await fetch(userInfoEndpoint, {
      method: "GET",
      headers: { Authorization: `Bearer ${accessToken}` },
      cache: "no-store",
    });
    if (!res.ok) {
      return false;
    }
    const info = (await res.json()) as Record<string, unknown>;
    return typeof info.sub === "string" && info.sub.trim() !== "" && isAdminUser(info);
  } catch {
    return false;
  }
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow public paths through without auth check
  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  // Check for session cookie
  const session = request.cookies.get("library_session")?.value;
  if (!session) {
    return unauthorized(request);
  }

  const valid = await validateAdminWithUserInfo(session);
  if (!valid) {
    return unauthorized(request);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
