import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { isAdminUser } from "@/lib/auth/admin-policy";
import { readSessionUser, verifyAdminSession } from "@/lib/auth/session";
import { fetchUserInfo } from "@/lib/auth/user-info";

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
  response.cookies.set("library_session_sig", "", COOKIE_CLEAR_OPTIONS);
  return response;
}

async function validateAdminWithUserInfo(
  accessToken: string,
): Promise<boolean> {
  const result = await fetchUserInfo(accessToken);
  if (!result.ok) {
    return false;
  }

  return isAdminUser(result.info);
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

  const userPayload = request.cookies.get("library_user")?.value || "";
  const sessionSignature =
    request.cookies.get("library_session_sig")?.value || "";
  if (
    (await verifyAdminSession(session, userPayload, sessionSignature)) &&
    readSessionUser(userPayload)
  ) {
    return NextResponse.next();
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
