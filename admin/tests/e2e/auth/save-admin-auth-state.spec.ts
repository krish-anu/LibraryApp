import { expect, mockAdminApis, test } from "../admin-fixture";

test("saved admin auth state restores access in a new browser context", async ({
  adminPage,
  browser,
  baseURL,
}, testInfo) => {
  const storageState = testInfo.outputPath("admin.json");
  await adminPage.context().storageState({ path: storageState });
  const context = await browser.newContext({ storageState, baseURL });
  try {
    const page = await context.newPage();
    await mockAdminApis(page);
    await page.goto("/dashboard");
    await expect(page.getByRole("heading", { name: /dashboard/i })).toBeVisible();
  } finally {
    await context.close();
  }
});
