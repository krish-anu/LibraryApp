import { NextRequest, NextResponse } from "next/server";
import { resolveAppUrl, sanitizeEnvValue } from "@/lib/auth/env";
import { signAdminSession } from "@/lib/auth/session";
import { resolveAdminIdentity } from "@/lib/auth/user-info";

// PKCE callback — exchanges the authorization code for tokens.
// Environment variables:
// ASGARDEO_TOKEN_ENDPOINT    – e.g. https://<org>.asgardeo.io/oauth2/token
// ASGARDEO_CLIENT_ID         – same public client ID used in /api/auth/login
// ASGARDEO_USERINFO_ENDPOINT – (optional) userinfo endpoint
// NEXT_PUBLIC_APP_URL         – e.g. http://localhost:3000

function callbackErrorDetail(error: unknown) {
  if (!(error instanceof Error)) {
    return "Unknown callback error";
  }

  const cause =
    error.cause && typeof error.cause === "object"
      ? (error.cause as { code?: unknown; message?: unknown })
      : undefined;
  const causeCode = typeof cause?.code === "string" ? cause.code : "";
  const causeMessage =
    typeof cause?.message === "string" ? cause.message : "";

  return [error.name, error.message, causeCode, causeMessage]
    .filter(Boolean)
    .join(": ");
}

async function getTokenJson(
  tokenEndpoint: string,
  headers: Record<string, string>,
  body: string,
) {
  const tokenRes = await fetch(tokenEndpoint, {
    method: "POST",
    headers,
    body,
  });

  const text = await tokenRes.text();
  let payload: Record<string, unknown> = {};
  try {
    payload = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  } catch {
    payload = { error: text || "Token endpoint returned a non-JSON response" };
  }

  return { ok: tokenRes.ok, status: tokenRes.status, payload };
}

export async function GET(req: NextRequest) {
  const appUrl = resolveAppUrl(req);

  try {
  const { searchParams } = new URL(req.url);
  const code = searchParams.get("code");
  const state = searchParams.get("state");
  const error = searchParams.get("error");
  const errorDescription = searchParams.get("error_description");

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
  if (!storedState || storedState !== state) {
    console.error(
      "[CALLBACK] State mismatch! stored:",
      !!storedState,
      "matches:",
      storedState === state,
    );
    return NextResponse.redirect(`${appUrl}/login?error=state_mismatch`);
  }

  // Retrieve code_verifier
  const codeVerifier = req.cookies.get("pkce_code_verifier")?.value;
  if (!codeVerifier) {
    console.error("[CALLBACK] Missing PKCE code_verifier cookie");
    return NextResponse.redirect(`${appUrl}/login?error=missing_verifier`);
  }
  const tokenEndpoint = sanitizeEnvValue(process.env.ASGARDEO_TOKEN_ENDPOINT);
  const clientId = sanitizeEnvValue(process.env.ASGARDEO_CLIENT_ID);
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
  const clientSecret = sanitizeEnvValue(process.env.ASGARDEO_CLIENT_SECRET);
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

  const tokenResult = await getTokenJson(
    tokenEndpoint,
    headers,
    params.toString(),
  );

  if (!tokenResult.ok) {
    const errorBody = tokenResult.payload;
    const detail =
      (typeof errorBody.error_description === "string"
        ? errorBody.error_description
        : "") ||
      (typeof errorBody.error === "string" ? errorBody.error : "") ||
      "Token exchange failed";
    console.error(
      "[CALLBACK] Token exchange failed:",
      tokenResult.status,
      detail,
      JSON.stringify(errorBody),
    );
    return NextResponse.redirect(
      `${appUrl}/login?error=${encodeURIComponent(detail)}`,
    );
  }

  const tokenJson = tokenResult.payload;
  const accessToken =
    typeof tokenJson.access_token === "string" ? tokenJson.access_token : "";
  const idToken = typeof tokenJson.id_token === "string" ? tokenJson.id_token : "";
  const expiresIn =
    typeof tokenJson.expires_in === "number" ? tokenJson.expires_in : 3600;

  if (!accessToken) {
    console.error("[CALLBACK] Token response did not include an access token");
    return NextResponse.redirect(
      `${appUrl}/login?error=${encodeURIComponent("Token response missing access token")}`,
    );
  }

  // Require an administrator claim before writing cookies. Asgardeo may expose
  // custom role claims through either userinfo or the issued tokens.
  const adminIdentity = await resolveAdminIdentity(accessToken, idToken);
  if (!adminIdentity.ok) {
    const message =
      adminIdentity.reason === "not_admin"
        ? "Administrator role is required"
        : "Unable to verify administrator role";
    return NextResponse.redirect(
      `${appUrl}/login?error=${encodeURIComponent(message)}`,
    );
  }
  const info = adminIdentity.info;
  const userPayload = JSON.stringify({
    sub: adminIdentity.user.sub,
    email: adminIdentity.user.email,
    name: adminIdentity.user.name,
    picture: info.picture || undefined,
  });
  const sessionSignature = await signAdminSession(accessToken, userPayload);

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
  if (sessionSignature) {
    respHeaders.append(
      "Set-Cookie",
      `library_session_sig=${sessionSignature}; Path=/; HttpOnly; Max-Age=${maxAge}; SameSite=Lax${securePart}`,
    );
  }
  // Clear PKCE cookies
  respHeaders.append("Set-Cookie", `pkce_code_verifier=; Path=/; Max-Age=0`);
  respHeaders.append("Set-Cookie", `pkce_state=; Path=/; Max-Age=0`);

  return new NextResponse(html, { status: 200, headers: respHeaders });
  } catch (error) {
    const detail = callbackErrorDetail(error);
    console.error("[CALLBACK] Unhandled callback failure:", detail);
    return NextResponse.redirect(
      `${appUrl}/login?error=${encodeURIComponent(`Callback failed: ${detail}`)}`,
    );
  }
}
