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

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow public paths through without auth check
  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  // Check for session cookie
  const session = request.cookies.get("library_session")?.value;

  if (!session) {
    // Never redirect API requests to /login; clients expect JSON/status codes.
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Redirect unauthenticated users to login
    const loginUrl = new URL("/login", request.url);
    return NextResponse.redirect(loginUrl);
  }

  // Validate the session token is a properly-formed JWT (basic check)
  // A JWT has 3 base64url-encoded parts separated by dots
  const jwtParts = session.split(".");
  if (jwtParts.length !== 3) {
    // Invalid token format — clear the cookie and redirect to login
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Invalid session" }, { status: 401 });
    }
    const loginUrl = new URL("/login", request.url);
    const response = NextResponse.redirect(loginUrl);
    response.cookies.set("library_session", "", { path: "/", maxAge: 0 });
    return response;
  }

  // Check token expiry from JWT payload
  try {
    const payload = JSON.parse(
      Buffer.from(jwtParts[1], "base64url").toString("utf-8"),
    );
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && typeof payload.exp === "number" && payload.exp < now) {
      // Token expired
      if (pathname.startsWith("/api/")) {
        return NextResponse.json({ error: "Session expired" }, { status: 401 });
      }
      const loginUrl = new URL("/login", request.url);
      const response = NextResponse.redirect(loginUrl);
      response.cookies.set("library_session", "", { path: "/", maxAge: 0 });
      response.cookies.set("library_id_token", "", { path: "/", maxAge: 0 });
      response.cookies.set("library_user", "", { path: "/", maxAge: 0 });
      return response;
    }
  } catch {
    // If we can't parse the JWT, reject
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Invalid session" }, { status: 401 });
    }
    const loginUrl = new URL("/login", request.url);
    const response = NextResponse.redirect(loginUrl);
    response.cookies.set("library_session", "", { path: "/", maxAge: 0 });
    return response;
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
