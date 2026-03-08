import { NextResponse } from "next/server";
import {
  generateCodeVerifier,
  generateCodeChallenge,
  generateState,
} from "@/lib/auth/pkce";

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

  const authUrl = `${authorizeEndpoint}?${params.toString()}`;

  const response = NextResponse.redirect(authUrl);

  // Store code_verifier and state in httpOnly cookies for the callback
  const cookieOptions = {
    httpOnly: true,
    secure: true,
    path: "/",
    maxAge: 600, // 10 minutes – enough time to complete login
    sameSite: "lax" as const,
  };

  response.cookies.set("pkce_code_verifier", codeVerifier, cookieOptions);
  response.cookies.set("pkce_state", state, cookieOptions);

  return response;
}
