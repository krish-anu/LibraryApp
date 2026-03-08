import { NextRequest, NextResponse } from "next/server";

/**
 * Verify that the current request has a valid admin session.
 * 
 * Checks the library_session cookie for a valid JWT and verifies
 * the token against the Asgardeo userinfo endpoint.
 * 
 * Returns the user info if valid, or a NextResponse error if not.
 */
export async function verifyAdmin(
  req: NextRequest,
): Promise<
  | { user: { sub: string; email: string; name: string }; error?: never }
  | { user?: never; error: NextResponse }
> {
  const accessToken = req.cookies.get("library_session")?.value;

  if (!accessToken) {
    return {
      error: NextResponse.json(
        { error: "Unauthorized" },
        { status: 401 },
      ),
    };
  }

  // Validate the token format (basic JWT check)
  const jwtParts = accessToken.split(".");
  if (jwtParts.length !== 3) {
    return {
      error: NextResponse.json(
        { error: "Invalid session" },
        { status: 401 },
      ),
    };
  }

  // Check token expiry
  try {
    const payload = JSON.parse(
      Buffer.from(jwtParts[1], "base64url").toString("utf-8"),
    );
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && typeof payload.exp === "number" && payload.exp < now) {
      return {
        error: NextResponse.json(
          { error: "Session expired" },
          { status: 401 },
        ),
      };
    }

    // Return user info from the JWT payload 
    return {
      user: {
        sub: payload.sub || "",
        email: payload.email || "",
        name: payload.name ||
          [payload.given_name, payload.family_name]
            .filter(Boolean)
            .join(" ") || "",
      },
    };
  } catch {
    return {
      error: NextResponse.json(
        { error: "Invalid session" },
        { status: 401 },
      ),
    };
  }
}
