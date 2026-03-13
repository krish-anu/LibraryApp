import { NextRequest, NextResponse } from "next/server";

/**
 * Verify that the current request has a valid admin session.
 *
 * Accepts either JWT or opaque access tokens.
 * - For JWTs, uses payload claims and exp locally.
 * - For opaque/non-decodable tokens, validates through userinfo endpoint.
 *
 * Returns the user info if valid, or a NextResponse error if not.
 */

type VerifiedUser = { sub: string; email: string; name: string };
type VerifyAdminResult =
  | { user: VerifiedUser; error?: never }
  | { user?: never; error: NextResponse };

type JwtPayload = {
  sub?: string;
  email?: string;
  name?: string;
  given_name?: string;
  family_name?: string;
  exp?: number;
};

function userFromStoredCookie(cookieValue?: string): VerifiedUser | null {
  if (!cookieValue) {
    return null;
  }

  try {
    const parsed = JSON.parse(
      decodeURIComponent(cookieValue),
    ) as Partial<VerifiedUser> | null;
    const sub = (parsed?.sub || "").trim();
    if (!sub) {
      return null;
    }

    return {
      sub,
      email: (parsed?.email || "").trim(),
      name: (parsed?.name || "").trim(),
    };
  } catch {
    return null;
  }
}

function parseJwtPayload(token: string): JwtPayload | null {
  const parts = token.split(".");
  if (parts.length !== 3) {
    return null;
  }

  try {
    return JSON.parse(Buffer.from(parts[1], "base64url").toString("utf-8"));
  } catch {
    return null;
  }
}

function userFromPayload(payload: JwtPayload): VerifiedUser | null {
  const sub = (payload.sub || "").trim();
  if (!sub) {
    return null;
  }

  return {
    sub,
    email: (payload.email || "").trim(),
    name:
      (payload.name || "").trim() ||
      [payload.given_name, payload.family_name].filter(Boolean).join(" "),
  };
}

function unauthorized(message: string): VerifyAdminResult {
  return {
    error: NextResponse.json({ error: message }, { status: 401 }),
  };
}

async function userFromUserInfo(accessToken: string): Promise<VerifiedUser | null> {
  const userinfoEndpoint = (
    process.env.ASGARDEO_USERINFO_ENDPOINT || ""
  ).trim();
  if (!userinfoEndpoint) {
    return null;
  }

  try {
    const res = await fetch(userinfoEndpoint, {
      headers: { Authorization: `Bearer ${accessToken}` },
      cache: "no-store",
    });
    if (!res.ok) {
      return null;
    }

    const info = await res.json();
    const sub = typeof info.sub === "string" ? info.sub.trim() : "";
    if (!sub) {
      return null;
    }

    return {
      sub,
      email: typeof info.email === "string" ? info.email : "",
      name:
        [info.given_name, info.family_name].filter(Boolean).join(" ") ||
        info.name ||
        info.preferred_username ||
        info.username ||
        "",
    };
  } catch {
    return null;
  }
}

export async function verifyAdmin(
  req: NextRequest,
): Promise<VerifyAdminResult> {
  const accessToken = req.cookies.get("library_session")?.value;
  const storedUser = userFromStoredCookie(
    req.cookies.get("library_user")?.value,
  );

  if (!accessToken) {
    return unauthorized("Unauthorized");
  }

  const jwtPayload = parseJwtPayload(accessToken);
  if (jwtPayload) {
    const now = Math.floor(Date.now() / 1000);
    if (
      typeof jwtPayload.exp === "number" &&
      Number.isFinite(jwtPayload.exp) &&
      jwtPayload.exp < now
    ) {
      return unauthorized("Session expired");
    }

    const jwtUser = userFromPayload(jwtPayload);
    if (jwtUser) {
      return { user: jwtUser };
    }
  }

  if (storedUser) {
    return { user: storedUser };
  }

  const user = await userFromUserInfo(accessToken);
  if (user) {
    return { user };
  }

  return unauthorized("Invalid session");
}
