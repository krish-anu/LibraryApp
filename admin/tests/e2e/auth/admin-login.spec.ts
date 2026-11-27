import { expect, test } from "@playwright/test";

test("admin sign in starts the Asgardeo authorization code flow with PKCE", async ({ page, baseURL }) => {
  const isAuthorization = (url: URL) => url.pathname.endsWith("/oauth2/authorize");
  await page.route(isAuthorization, (route) => route.fulfill({ body: "Test identity provider" }));
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: "Library Admin" })).toBeVisible();
  const authorizationRequest = page.waitForRequest((request) =>
    isAuthorization(new URL(request.url())),
  );
  await page.getByRole("button", { name: /sign in with asgardeo/i }).click();
  const authorization = new URL((await authorizationRequest).url());
  expect(authorization.searchParams.get("response_type")).toBe("code");
  expect(authorization.searchParams.get("redirect_uri")).toBe(
    `${baseURL}/api/auth/callback/asgardeo`,
  );
  expect(authorization.searchParams.get("state")).toBeTruthy();
  expect(authorization.searchParams.get("code_challenge_method")).toBe("S256");
  expect(authorization.searchParams.get("code_challenge")).toMatch(/^[A-Za-z0-9_-]{43}$/);
});
