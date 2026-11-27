import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin can create a member with validated contact details", async ({ adminPage: page }) => {
  let savedMember: Record<string, unknown> | undefined;
  await mockAdminApis(page, {
    "GET /api/users": (route) => route.fulfill({
      json: { data: savedMember ? [savedMember] : [], totalCount: savedMember ? 1 : 0 },
    }),
    "POST /api/users": (route) => {
      savedMember = { id: "u-new", ...route.request().postDataJSON() };
      return route.fulfill({ status: 201, json: { data: savedMember } });
    },
  });
  await page.goto("/users");
  await page.getByRole("button", { name: /create new user/i }).click();
  const form = page.getByRole("dialog");
  await form.getByLabel("Full Name").fill("New QA Member");
  await form.getByLabel("Email").fill("invalid-email");
  await form.getByRole("button", { name: "Create User" }).click();
  await expect(form.locator('input[type="email"]:invalid')).toBeVisible();
  await form.getByLabel("Email").fill("new-member@example.com");
  await form.getByRole("button", { name: "Create User" }).click();

  await expect(form).toBeHidden();
  await expect(page.getByRole("button", { name: "Edit New QA Member" })).toBeVisible();
  expect(savedMember).toMatchObject({
    name: "New QA Member",
    email: "new-member@example.com",
  });
});
