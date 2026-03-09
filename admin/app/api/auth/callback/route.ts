import { NextRequest, NextResponse } from "next/server";

// PKCE callback — exchanges the authorization code for tokens.
// Environment variables:
// ASGARDEO_TOKEN_ENDPOINT    – e.g. https://<org>.asgardeo.io/oauth2/token
// ASGARDEO_CLIENT_ID         – same public client ID used in /api/auth/login
// ASGARDEO_USERINFO_ENDPOINT – (optional) userinfo endpoint
// NEXT_PUBLIC_APP_URL         – e.g. http://localhost:3000

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const code = searchParams.get("code");
  const state = searchParams.get("state");
  const error = searchParams.get("error");
  const errorDescription = searchParams.get("error_description");

  const appUrl = process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000";

  // Handle error response from IdP
  if (error) {
    console.error("OAuth callback error:", error, errorDescription);
    return NextResponse.redirect(
      `${appUrl}/login?error=${encodeURIComponent(errorDescription || error)}`,
    );
  }

  if (!code) {
    return NextResponse.redirect(`${appUrl}/login?error=missing_code`);
  }

  // Validate state
  const storedState = req.cookies.get("pkce_state")?.value;
  if (!storedState || storedState !== state) {
    console.error("OAuth state mismatch");
    return NextResponse.redirect(`${appUrl}/login?error=state_mismatch`);
  }

  // Retrieve code_verifier
  const codeVerifier = req.cookies.get("pkce_code_verifier")?.value;
  if (!codeVerifier) {
    console.error("Missing PKCE code_verifier cookie");
    return NextResponse.redirect(`${appUrl}/login?error=missing_verifier`);
  }

  const tokenEndpoint = process.env.ASGARDEO_TOKEN_ENDPOINT;
  const clientId = process.env.ASGARDEO_CLIENT_ID;
  const redirectUri = `${appUrl}/api/auth/callback`;

  if (!tokenEndpoint || !clientId) {
    console.error("Missing ASGARDEO_TOKEN_ENDPOINT or ASGARDEO_CLIENT_ID");
    return NextResponse.redirect(
      `${appUrl}/login?error=server_misconfiguration`,
    );
  }

  // Exchange authorization code + code_verifier for tokens
  const params = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    redirect_uri: redirectUri,
    code_verifier: codeVerifier,
  });

  // Include client authentication if a client secret is configured.
  const clientSecret = process.env.ASGARDEO_CLIENT_SECRET || "";
  const headers: Record<string, string> = {
    "Content-Type": "application/x-www-form-urlencoded",
  };
  if (clientSecret) {
    const basic = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
    headers["Authorization"] = `Basic ${basic}`;
  } else if (clientId) {
    // For public clients (no secret) include client_id in the body
    params.append("client_id", clientId);
  }

  const tokenRes = await fetch(tokenEndpoint, {
    method: "POST",
    headers,
    body: params.toString(),
  });

  if (!tokenRes.ok) {
    const errorBody = await tokenRes.json().catch(() => ({}));
    const detail =
      errorBody?.error_description ||
      errorBody?.error ||
      "Token exchange failed";
    console.error("/api/auth/callback token error:", detail);
    return NextResponse.redirect(
      `${appUrl}/login?error=${encodeURIComponent(detail)}`,
    );
  }

  const tokenJson = await tokenRes.json();
  const accessToken = tokenJson.access_token;
  const idToken = tokenJson.id_token || "";
  const expiresIn = tokenJson.expires_in || 3600;

  // Fetch userinfo
  let userPayload: string = JSON.stringify({ sub: "", email: "", name: "" });
  try {
    const userinfoEndpoint = (
      process.env.ASGARDEO_USERINFO_ENDPOINT || ""
    ).trim();
    if (userinfoEndpoint && accessToken) {
      const ures = await fetch(userinfoEndpoint, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (ures.ok) {
        const info = await ures.json();
        userPayload = JSON.stringify({
          sub: info.sub || "",
          email: info.email || "",
          name:
            [info.given_name, info.family_name].filter(Boolean).join(" ") ||
            info.preferred_username ||
            info.username ||
            "",
          picture: info.picture || undefined,
        });
      }
    }
  } catch {
    // userinfo is best-effort
  }

  const response = NextResponse.redirect(`${appUrl}/dashboard`);

  const isProduction = process.env.NODE_ENV === "production";
  const cookieOptions = {
    httpOnly: true,
    secure: isProduction,
    path: "/",
    maxAge: Number(expiresIn),
    sameSite: "lax" as const,
  };

  // Store session tokens in httpOnly cookies
  response.cookies.set("library_session", accessToken, cookieOptions);
  response.cookies.set("library_id_token", idToken, {
    ...cookieOptions,
    // id_token is needed for logout redirect
  });
  // Store user info in a httpOnly cookie for security
  response.cookies.set("library_user", userPayload, {
    ...cookieOptions,
    httpOnly: true,
  });

  // Clear PKCE cookies
  response.cookies.set("pkce_code_verifier", "", { path: "/", maxAge: 0 });
  response.cookies.set("pkce_state", "", { path: "/", maxAge: 0 });

  return response;
}
