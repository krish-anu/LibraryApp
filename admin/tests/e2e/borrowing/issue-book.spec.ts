import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin circulation shows active loans without exposing a second issue path", async ({ adminPage: page }) => {
  await mockAdminApis(page);
  await page.goto("/returns");
  await expect(page.getByRole("heading", { name: "Book Returns" })).toBeVisible();
  await expect(page.getByRole("button", { name: /issue book/i })).toHaveCount(0);
});
