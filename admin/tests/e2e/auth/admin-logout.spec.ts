import { expect, test, mockAdminApis } from "../admin-fixture";

test("admin logout clears session cookies", async ({ adminPage: page }) => {
  await mockAdminApis(page, { "GET /api/auth/logout": (route) => route.continue() });
  await page.goto("/dashboard");
  await page.getByRole("button", { name: "Open admin profile menu" }).click();
  await page.getByRole("button", { name: /logout|sign out/i }).click();
  await expect(page).toHaveURL(/\/login/);
  const cookies = await page.context().cookies();
  expect(cookies.filter(({ name }) => name.startsWith("library_"))).toEqual([]);
});
