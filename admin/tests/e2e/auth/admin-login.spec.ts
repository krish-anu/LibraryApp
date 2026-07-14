import { expect, test } from "@playwright/test";

test("admin login page starts Asgardeo flow", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: "Library Admin" })).toBeVisible();
  await expect(page.getByRole("button", { name: /sign in with asgardeo/i })).toBeVisible();
});
