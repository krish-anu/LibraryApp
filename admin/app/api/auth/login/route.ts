import { NextResponse } from "next/server";

// Server-side route to exchange credentials with Asgardeo using ROPC grant.
// Uses the public mobile Asgardeo application that has the "password" grant enabled.
// Expected environment vars:
// ASGARDEO_TOKEN_ENDPOINT  - full token endpoint URL
// ASGARDEO_ROPC_CLIENT_ID  - public client ID with ROPC grant enabled
// ASGARDEO_USERINFO_ENDPOINT (optional)
// ASGARDEO_SCOPE (optional, defaults to "openid profile email")

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { email, password } = body || {};
    if (!email || !password) {
      return NextResponse.json(
        { message: "Missing credentials" },
        { status: 400 },
      );
    }

    const tokenEndpoint = process.env.ASGARDEO_TOKEN_ENDPOINT;
    // Use the ROPC-enabled public client (mobile app's Asgardeo application)
    const ropcClientId = process.env.ASGARDEO_ROPC_CLIENT_ID;
    const scope = process.env.ASGARDEO_SCOPE || "openid profile email";

    if (!tokenEndpoint || !ropcClientId) {
      return NextResponse.json(
        {
          message:
            "Server misconfiguration: ASGARDEO_TOKEN_ENDPOINT and ASGARDEO_ROPC_CLIENT_ID are required",
        },
        { status: 500 },
      );
    }

    // ROPC request — public client, no client_secret needed
    const params = new URLSearchParams();
    params.append("grant_type", "password");
    params.append("username", email);
    params.append("password", password);
    params.append("scope", scope);
    params.append("client_id", ropcClientId);

    const tokenRes = await fetch(tokenEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params.toString(),
    });

    if (!tokenRes.ok) {
      const errorBody = await tokenRes.json().catch(() => ({}));
      const detail =
        errorBody?.error_description ||
        errorBody?.error ||
        "Authentication failed";
      console.error("/api/auth/login token error:", detail);
      return NextResponse.json({ message: detail }, { status: 401 });
    }

    const tokenJson = await tokenRes.json();
    const accessToken = tokenJson.access_token;
    const expiresIn = tokenJson.expires_in || 3600;

    // Fetch userinfo to populate the session user object
    let user: any = null;
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
          user = {
            sub: info.sub || "",
            email: info.email || email,
            name:
              [info.given_name, info.family_name].filter(Boolean).join(" ") ||
              info.preferred_username ||
              info.username ||
              email,
            picture: info.picture || undefined,
          };
        }
      }
    } catch (e) {
      // ignore userinfo errors — login still succeeds
    }

    // Fallback user if userinfo endpoint was unavailable
    if (!user) {
      user = { sub: "", email, name: email };
    }

    const res = NextResponse.json({ user });

    // Set secure httpOnly cookie with access token
    res.cookies.set({
      name: "library_session",
      value: accessToken,
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: Number(expiresIn),
      sameSite: "lax",
    });

    return res;
  } catch (err: any) {
    console.error("/api/auth/login error", err);
    return NextResponse.json(
      { message: "Internal server error" },
      { status: 500 },
    );
  }
}
