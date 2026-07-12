import { NextRequest, NextResponse } from "next/server";
import { resolveAppUrl } from "@/lib/auth/env";

export async function GET(req: NextRequest) {
  const appUrl = resolveAppUrl(req);
  const message =
    "Outdated Asgardeo callback URL. Configure the application callback URL as /api/auth/callback/asgardeo.";

  return NextResponse.redirect(
    `${appUrl}/login?error=${encodeURIComponent(message)}`,
  );
}
