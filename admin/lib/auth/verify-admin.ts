import { NextRequest, NextResponse } from "next/server";
import { isAdminUser } from "@/lib/auth/admin-policy";
import { readSessionUser, verifyAdminSession } from "@/lib/auth/session";
import {
  fetchUserInfo,
  userFromInfo,
  type VerifiedUser,
} from "@/lib/auth/user-info";

/**
 * Verify that the current request has a valid admin session.
 *
 * Validates the access token through the identity provider and requires an
 * administrator claim before allowing admin API access.
 *
 * Returns the user info if valid, or a NextResponse error if not.
 */

type VerifyAdminResult =
  | { user: VerifiedUser; error?: never }
  | { user?: never; error: NextResponse };

function unauthorized(message: string): VerifyAdminResult {
  return {
    error: NextResponse.json({ error: message }, { status: 401 }),
  };
}

async function adminFromUserInfo(
  accessToken: string,
): Promise<VerifiedUser | null> {
  const result = await fetchUserInfo(accessToken);
  if (!result.ok) {
    return null;
  }

  return isAdminUser(result.info) ? userFromInfo(result.info) : null;
}

export async function verifyAdmin(
  req: NextRequest,
): Promise<VerifyAdminResult> {
  const accessToken = req.cookies.get("library_session")?.value;

  if (!accessToken) {
    return unauthorized("Unauthorized");
  }

  const userPayload = req.cookies.get("library_user")?.value || "";
  const sessionSignature = req.cookies.get("library_session_sig")?.value || "";
  if (
    await verifyAdminSession(accessToken, userPayload, sessionSignature)
  ) {
    const user = readSessionUser(userPayload);
    if (user) {
      return { user };
    }
  }

  const user = await adminFromUserInfo(accessToken);
  if (user) {
    return { user };
  }

  return unauthorized("Invalid admin session");
}
