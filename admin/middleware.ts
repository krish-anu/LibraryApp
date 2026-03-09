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

function parseJwtPayload(token: string): { exp?: number } | null {
  const parts = token.split(".");
  if (parts.length !== 3) {
    return null;
  }

  try {
    const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4);
    const json = atob(padded);
    return JSON.parse(json) as { exp?: number };
  } catch {
    return null;
  }
}

async function validateWithUserInfo(accessToken: string): Promise<boolean> {
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
    return res.ok;
  } catch {
    return false;
  }
}

export async function middleware(request: NextRequest) {
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

  // JWT tokens can be checked locally for expiry.
  const payload = parseJwtPayload(session);
  if (payload) {
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && typeof payload.exp === "number" && payload.exp < now) {
      return unauthorized(request);
    }
    return NextResponse.next();
  }

  // Non-JWT token (opaque/JWE): validate through userinfo endpoint.
  const valid = await validateWithUserInfo(session);
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
