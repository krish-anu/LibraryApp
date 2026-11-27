import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin deletion of a member requires explicit confirmation", async ({ adminPage: page }) => {
  const member = { id: "u1", name: "Active Member", email: "member@example.com" };
  let deactivated = false;
  await mockAdminApis(page, {
    "GET /api/users": (route) => route.fulfill({
      json: { data: deactivated ? [] : [member], totalCount: deactivated ? 0 : 1 },
    }),
    "DELETE /api/users/u1": (route) => {
      deactivated = true;
      return route.fulfill({ json: { success: true } });
    },
  });
  await page.goto("/users");
  page.once("dialog", async (dialog) => {
    expect(dialog.type()).toBe("confirm");
    await dialog.dismiss();
  });
  const deactivateButton = page.getByRole("button", { name: "Delete Active Member" });
  await deactivateButton.click();
  await expect(deactivateButton).toBeVisible();
  expect(deactivated).toBe(false);

  page.once("dialog", (dialog) => dialog.accept());
  await deactivateButton.click();
  await expect(deactivateButton).toBeHidden();
  expect(deactivated).toBe(true);
});
