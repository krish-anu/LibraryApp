import { NextResponse } from "next/server";
import {
  generateCodeVerifier,
  generateCodeChallenge,
  generateState,
} from "@/lib/auth/pkce";

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

// PKCE Authorization Code flow — initiates the login redirect.
// Environment variables:
// ASGARDEO_AUTHORIZE_ENDPOINT – e.g. https://<org>.asgardeo.io/oauth2/authorize
// ASGARDEO_CLIENT_ID          – public OAuth2 client ID (PKCE-enabled app)
// ASGARDEO_SCOPE              – (optional) defaults to "openid profile email"
// NEXT_PUBLIC_APP_URL          – e.g. http://localhost:3000

export async function GET() {
  const authorizeEndpoint = process.env.ASGARDEO_AUTHORIZE_ENDPOINT;
  const clientId = process.env.ASGARDEO_CLIENT_ID;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000";
  const scope = process.env.ASGARDEO_SCOPE || "openid profile email";
  const prompt = (process.env.ASGARDEO_PROMPT || "login").trim();

  if (!authorizeEndpoint || !clientId) {
    return NextResponse.json(
      {
        message:
          "Server misconfiguration: ASGARDEO_AUTHORIZE_ENDPOINT and ASGARDEO_CLIENT_ID are required",
      },
      { status: 500 },
    );
  }

  const codeVerifier = generateCodeVerifier();
  const codeChallenge = generateCodeChallenge(codeVerifier);
  const state = generateState();
  // Use the callback path registered in Asgardeo application settings
  const redirectUri = `${appUrl}/api/auth/callback/asgardeo`;

  const params = new URLSearchParams({
    response_type: "code",
    client_id: clientId,
    redirect_uri: redirectUri,
    scope,
    state,
    code_challenge: codeChallenge,
    code_challenge_method: "S256",
  });
  if (prompt) {
    params.set("prompt", prompt);
  }

  const authUrl = `${authorizeEndpoint}?${params.toString()}`;

  // Return an HTML page that sets cookies (via Set-Cookie headers on a 200
  // response) and THEN redirects.  Using a 307 redirect with Set-Cookie is
  // unreliable — some browsers/environments don't persist cookies on redirect
  // responses before following the Location header.
  const isProduction = process.env.NODE_ENV === "production";
  const cookieOptions = {
    httpOnly: true,
    secure: isProduction,
    path: "/",
    maxAge: 600, // 10 minutes – enough time to complete login
    sameSite: "lax" as const,
  };

  const escapedAuthUrl = escapeHtml(authUrl);
  const redirectScriptTarget = JSON.stringify(authUrl);

  const html = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta http-equiv="refresh" content="2;url=${escapedAuthUrl}" />
    <title>Redirecting to Asgardeo</title>
    <style>
      :root {
        color-scheme: light;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
        font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background:
          radial-gradient(circle at top, rgba(89, 138, 198, 0.45), transparent 32%),
          linear-gradient(160deg, #1e3a5f 0%, #152a46 52%, #0f1d31 100%);
      }

      .card {
        width: min(100%, 440px);
        padding: 32px 28px;
        border-radius: 28px;
        background: rgba(255, 255, 255, 0.96);
        box-shadow: 0 24px 70px rgba(15, 23, 42, 0.28);
        text-align: center;
      }

      .badge {
        width: 64px;
        height: 64px;
        margin: 0 auto 20px;
        border-radius: 20px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 22px;
        font-weight: 700;
        letter-spacing: 0.08em;
        color: #ffffff;
        background: linear-gradient(135deg, #1e3a5f 0%, #3f6ea6 100%);
      }

      .spinner {
        width: 44px;
        height: 44px;
        margin: 0 auto 20px;
        border-radius: 999px;
        border: 4px solid rgba(30, 58, 95, 0.16);
        border-top-color: #1e3a5f;
        animation: spin 0.9s linear infinite;
      }

      h1 {
        margin: 0;
        font-size: 1.6rem;
        line-height: 1.2;
        color: #0f172a;
      }

      p {
        margin: 12px 0 0;
        font-size: 0.98rem;
        line-height: 1.6;
        color: #475569;
      }

      .hint {
        margin-top: 18px;
        font-size: 0.92rem;
        color: #64748b;
      }

      a {
        color: #1e3a5f;
        font-weight: 600;
      }

      @keyframes spin {
        to {
          transform: rotate(360deg);
        }
      }
    </style>
  </head>
  <body>
    <main class="card" role="status" aria-live="polite">
      <div class="badge" aria-hidden="true">LM</div>
      <div class="spinner" aria-hidden="true"></div>
      <h1>Redirecting to secure sign in</h1>
      <p>Preparing your Asgardeo login and taking you to the authentication page.</p>
      <p class="hint">
        If the redirect does not start automatically,
        <a href="${escapedAuthUrl}">continue to Asgardeo</a>.
      </p>
    </main>
    <script>
      window.setTimeout(function () {
        window.location.replace(${redirectScriptTarget});
      }, 150);
    </script>
  </body>
</html>`;

  const response = new NextResponse(html, {
    status: 200,
    headers: { "Content-Type": "text/html" },
  });

  response.cookies.set("pkce_code_verifier", codeVerifier, cookieOptions);
  response.cookies.set("pkce_state", state, cookieOptions);

  return response;
}
