import { NextRequest, NextResponse } from "next/server";

// Returns the current session user from the library_session cookie.
// Used by the client-side auth context to hydrate user state.

export async function GET(req: NextRequest) {
  const accessToken = req.cookies.get("library_session")?.value;

  if (!accessToken) {
    return NextResponse.json(
      { authenticated: false, user: null },
      { status: 401 },
    );
  }

  // Try to read the user cookie first (set at login)
  const userCookie = req.cookies.get("library_user")?.value;
  if (userCookie) {
    try {
      const user = JSON.parse(userCookie);
      return NextResponse.json({ authenticated: true, user });
    } catch {
      // fall through to userinfo
    }
  }

  // Fallback: call userinfo endpoint
  const userinfoEndpoint = (
    process.env.ASGARDEO_USERINFO_ENDPOINT || ""
  ).trim();

  if (userinfoEndpoint) {
    try {
      const res = await fetch(userinfoEndpoint, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (res.ok) {
        const info = await res.json();
        const user = {
          sub: info.sub || "",
          email: info.email || "",
          name:
            [info.given_name, info.family_name].filter(Boolean).join(" ") ||
            info.preferred_username ||
            info.username ||
            "",
          picture: info.picture || undefined,
        };
        return NextResponse.json({ authenticated: true, user });
      }
    } catch {
      // token likely expired
    }
  }

  // Token invalid or expired
  return NextResponse.json(
    { authenticated: false, user: null },
    { status: 401 },
  );
}
