import fs from "node:fs";
import path from "node:path";
import { expect, test } from "@playwright/test";

const authStatePath = process.env.ADMIN_E2E_AUTH_STATE || ".auth/admin.json";
const adminEmail = process.env.E2E_ADMIN_EMAIL;
const adminPassword = process.env.E2E_ADMIN_PASSWORD;

test("save admin Asgardeo auth state", async ({ page }) => {
  test.skip(
    !adminEmail || !adminPassword,
    "Set E2E_ADMIN_EMAIL and E2E_ADMIN_PASSWORD in admin/.env.e2e.local.",
  );

  await page.goto("/login");
  await page.getByRole("button", { name: /sign in with asgardeo/i }).click();

  await page.waitForLoadState("domcontentloaded");

  const username = page
    .getByLabel(/email|username/i)
    .or(page.getByPlaceholder(/email|username/i))
    .or(page.locator('input[name="username"], input[name="email"], input[type="email"]'))
    .first();

  const password = page
    .getByLabel(/password/i)
    .or(page.getByPlaceholder(/password/i))
    .or(page.locator('input[name="password"], input[type="password"]'))
    .first();

  await username.fill(adminEmail!);
  await password.fill(adminPassword!);
  await page.getByRole("button", { name: /sign in|login|continue/i }).click();

  await expect(page).toHaveURL(/\/dashboard/, { timeout: 60_000 });
  await expect(page.getByRole("heading", { name: /dashboard/i })).toBeVisible();

  fs.mkdirSync(path.dirname(authStatePath), { recursive: true });
  await page.context().storageState({ path: authStatePath });
});
