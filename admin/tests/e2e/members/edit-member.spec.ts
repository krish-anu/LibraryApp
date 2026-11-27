import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin can edit member contact details", async ({ adminPage: page }) => {
  let member = {
    id: "u1",
    name: "QA Member",
    email: "member@example.com",
    phone: "0771234567",
    address: "Main Street",
    role: "member",
  };
  await mockAdminApis(page, {
    "GET /api/users": (route) => route.fulfill({ json: { data: [member], totalCount: 1 } }),
    "PUT /api/users/u1": (route) => {
      member = { ...member, ...route.request().postDataJSON() };
      return route.fulfill({ json: { data: member } });
    },
  });
  await page.goto("/users");
  await expect(page.locator("p:visible", { hasText: "QA Member" }).first()).toBeVisible();
  await page.locator('button[aria-label="Edit QA Member"]:visible').click();
  const form = page.getByRole("dialog");
  await expect(form.getByLabel("Phone")).toHaveValue("0771234567");
  await form.getByLabel("Phone").fill("0779876543");
  await form.getByRole("button", { name: "Update User" }).click();
  await expect(form).toBeHidden();
  expect(member.phone).toBe("0779876543");
});
