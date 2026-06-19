import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";

// Returns the current session user from the library_session cookie.
// Used by the client-side auth context to hydrate user state.

export async function GET(req: NextRequest) {
  const auth = await verifyAdmin(req);
  if (auth.error) {
    return NextResponse.json(
      { authenticated: false, user: null },
      { status: 401 },
    );
  }

  return NextResponse.json({ authenticated: true, user: auth.user });
}
