import { NextRequest, NextResponse } from "next/server";

/**
 * Verify that the current request has a valid admin session.
 *
 * Validates the access token through the identity provider and requires an
 * administrator claim before allowing admin API access.
 *
 * Returns the user info if valid, or a NextResponse error if not.
 */

type VerifiedUser = { sub: string; email: string; name: string };
type VerifyAdminResult =
  | { user: VerifiedUser; error?: never }
  | { user?: never; error: NextResponse };

type UserInfo = Record<string, unknown>;

function unauthorized(message: string): VerifyAdminResult {
  return {
    error: NextResponse.json({ error: message }, { status: 401 }),
  };
}

async function userFromUserInfo(
  accessToken: string,
): Promise<VerifiedUser | null> {
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

    const info = (await res.json()) as UserInfo;
    const sub = typeof info.sub === "string" ? info.sub.trim() : "";
    if (!sub) {
      return null;
    }

    return {
      sub,
      email: typeof info.email === "string" ? info.email : "",
      name:
        [info.given_name, info.family_name].filter(Boolean).join(" ") ||
        (typeof info.name === "string" ? info.name : "") ||
        (typeof info.preferred_username === "string"
          ? info.preferred_username
          : "") ||
        (typeof info.username === "string" ? info.username : "") ||
        "",
    };
  } catch {
    return null;
  }
}

function csvEnv(name: string, fallback = "") {
  return new Set(
    (process.env[name] || fallback)
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean),
  );
}

function hasAdminRestriction() {
  return csvEnv("ADMIN_EMAILS").size > 0 || csvEnv("ADMIN_GROUPS").size > 0;
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

async function adminFromUserInfo(
  accessToken: string,
): Promise<VerifiedUser | null> {
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

    const info = (await res.json()) as UserInfo;
    const user = await userFromUserInfo(accessToken);
    if (!user) {
      return null;
    }

    if (!hasAdminRestriction()) {
      return user;
    }

    const allowedEmails = csvEnv("ADMIN_EMAILS");
    if (user.email && allowedEmails.has(user.email.toLowerCase())) {
      return user;
    }

    const allowedGroups = csvEnv(
      "ADMIN_GROUPS",
      "admin,library-admin,library_admin,Library Administrator",
    );
    const userClaims = new Set<string>();
    ["groups", "roles", "role", "permissions", "scope"].forEach((claim) => {
      claimValues(info[claim]).forEach((value) => userClaims.add(value));
    });

    return [...userClaims].some((claim) => allowedGroups.has(claim))
      ? user
      : null;
  } catch {
    return null;
  }
}

export async function verifyAdmin(
  req: NextRequest,
): Promise<VerifyAdminResult> {
  const accessToken = req.cookies.get("library_session")?.value;

  if (!accessToken) {
    return unauthorized("Unauthorized");
  }

  const user = await adminFromUserInfo(accessToken);
  if (user) {
    return { user };
  }

  return unauthorized("Invalid admin session");
}
