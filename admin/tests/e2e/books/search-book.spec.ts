import { expect, test } from "@playwright/test";

test.skip(!process.env.ADMIN_E2E_AUTH_STATE, "Requires admin storage state.");
test.use(process.env.ADMIN_E2E_AUTH_STATE ? { storageState: process.env.ADMIN_E2E_AUTH_STATE } : {});

test("admin can search and filter books", async ({ page }) => {
  await page.goto("/books");
  await page.getByPlaceholder("Search books...").fill("qa");
  await expect(page.getByRole("heading", { name: "Book Inventory" })).toBeVisible();
});
