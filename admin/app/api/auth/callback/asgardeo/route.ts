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

  console.log("[CALLBACK] Start — code:", !!code, "state:", !!state);
  console.log("[CALLBACK] All cookies:", req.cookies.getAll().map(c => c.name));

  // Handle error response from IdP
  if (error) {
    console.error("[CALLBACK] OAuth IdP error:", error, errorDescription);
    return NextResponse.redirect(
      `${appUrl}/login?error=${encodeURIComponent(errorDescription || error)}`,
    );
  }

  if (!code) {
    console.error("[CALLBACK] Missing code");
    return NextResponse.redirect(`${appUrl}/login?error=missing_code`);
  }

  // Validate state
  const storedState = req.cookies.get("pkce_state")?.value;
  console.log("[CALLBACK] storedState:", storedState ? storedState.substring(0, 10) + "..." : "MISSING");
  console.log("[CALLBACK] incomingState:", state ? state.substring(0, 10) + "..." : "MISSING");
  if (!storedState || storedState !== state) {
    console.error("[CALLBACK] State mismatch! stored:", !!storedState, "matches:", storedState === state);
    return NextResponse.redirect(`${appUrl}/login?error=state_mismatch`);
  }

  // Retrieve code_verifier
  const codeVerifier = req.cookies.get("pkce_code_verifier")?.value;
  if (!codeVerifier) {
    console.error("[CALLBACK] Missing PKCE code_verifier cookie");
    return NextResponse.redirect(`${appUrl}/login?error=missing_verifier`);
  }
  console.log("[CALLBACK] PKCE cookies present, proceeding to token exchange");

  const tokenEndpoint = process.env.ASGARDEO_TOKEN_ENDPOINT;
  const clientId = process.env.ASGARDEO_CLIENT_ID;
  const redirectUri = `${appUrl}/api/auth/callback/asgardeo`;

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
    console.error("[CALLBACK] Token exchange failed:", tokenRes.status, detail, JSON.stringify(errorBody));
    return NextResponse.redirect(
      `${appUrl}/login?error=${encodeURIComponent(detail)}`,
    );
  }

  const tokenJson = await tokenRes.json();
  console.log("[CALLBACK] Token exchange success, access_token:", !!tokenJson.access_token);
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

  // Build Set-Cookie headers manually to bypass Next.js cookie API issues.
  // Use JavaScript redirect (not meta-refresh) to ensure the browser has fully
  // processed and persisted the Set-Cookie response headers before navigating.
  const isProduction = process.env.NODE_ENV === "production";
  const maxAge = Number(expiresIn);
  const securePart = isProduction ? "; Secure" : "";

  const dashboardUrl = `${appUrl}/dashboard`;
  const html = `<!DOCTYPE html>
<html><head><title>Signing in…</title></head>
<body>
<p>Signing in…</p>
<script>window.location.replace("${dashboardUrl}");</script>
</body></html>`;

  const respHeaders = new Headers();
  respHeaders.set("Content-Type", "text/html; charset=utf-8");
  respHeaders.set("Cache-Control", "no-store");
  // Session cookies — use append so each Set-Cookie is its own header
  respHeaders.append(
    "Set-Cookie",
    `library_session=${accessToken}; Path=/; HttpOnly; Max-Age=${maxAge}; SameSite=Lax${securePart}`,
  );
  respHeaders.append(
    "Set-Cookie",
    `library_id_token=${idToken}; Path=/; HttpOnly; Max-Age=${maxAge}; SameSite=Lax${securePart}`,
  );
  respHeaders.append(
    "Set-Cookie",
    `library_user=${encodeURIComponent(userPayload)}; Path=/; HttpOnly; Max-Age=${maxAge}; SameSite=Lax${securePart}`,
  );
  // Clear PKCE cookies
  respHeaders.append(
    "Set-Cookie",
    `pkce_code_verifier=; Path=/; Max-Age=0`,
  );
  respHeaders.append(
    "Set-Cookie",
    `pkce_state=; Path=/; Max-Age=0`,
  );

  console.log("[CALLBACK] Returning 200 HTML with", respHeaders.getSetCookie().length, "Set-Cookie headers");

  return new NextResponse(html, { status: 200, headers: respHeaders });
}
