import { expect, mockAdminApis, test } from "../admin-fixture";

test("fine settings expose grace, daily rate, and cap inputs", async ({ adminPage: page }) => {
  await mockAdminApis(page);
  await page.goto("/settings");
  await expect(page.getByLabel("Grace Period (days)")).toHaveValue("2");
  await expect(page.getByLabel("Daily Fine Rate (LKR)")).toHaveValue("0.5");
  await expect(page.getByLabel("Maximum Fine Cap (LKR)")).toHaveValue("25");
});
