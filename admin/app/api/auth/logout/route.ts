import { NextRequest, NextResponse } from "next/server";
import { resolveAppUrl, sanitizeEnvValue } from "@/lib/auth/env";

// Logout — clears session cookies and optionally performs RP-initiated logout
// Environment variables:
// ASGARDEO_LOGOUT_ENDPOINT – (optional) e.g. https://<org>.asgardeo.io/oidc/logout
// ASGARDEO_CLIENT_ID       – same client ID
// NEXT_PUBLIC_APP_URL       – e.g. http://localhost:3000

export async function GET(req: NextRequest) {
  const appUrl = resolveAppUrl(req);
  const logoutEndpoint = sanitizeEnvValue(
    process.env.ASGARDEO_LOGOUT_ENDPOINT,
  );
  const clientId = sanitizeEnvValue(process.env.ASGARDEO_CLIENT_ID);
  const idToken = req.cookies.get("library_id_token")?.value || "";

  // Clear all session cookies
  const clearCookie = (name: string) => ({
    name,
    value: "",
    path: "/",
    maxAge: 0,
  });

  // If we have a logout endpoint, redirect to IdP logout
  if (logoutEndpoint && idToken) {
    const params = new URLSearchParams({
      id_token_hint: idToken,
      client_id: clientId,
      post_logout_redirect_uri: `${appUrl}/login`,
    });

    const response = NextResponse.redirect(
      `${logoutEndpoint}?${params.toString()}`,
    );
    response.cookies.set(clearCookie("library_session"));
    response.cookies.set(clearCookie("library_id_token"));
    response.cookies.set(clearCookie("library_user"));
    return response;
  }

  // Fallback: just clear cookies and redirect to login
  const response = NextResponse.redirect(`${appUrl}/login`);
  response.cookies.set(clearCookie("library_session"));
  response.cookies.set(clearCookie("library_id_token"));
  response.cookies.set(clearCookie("library_user"));
  return response;
}
