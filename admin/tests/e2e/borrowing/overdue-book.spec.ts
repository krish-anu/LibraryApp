import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin sees overdue loan due dates in the return queue", async ({ adminPage: page }) => {
  await mockAdminApis(page, {
    "/api/returns": async (route) =>
      route.fulfill({
        contentType: "application/json",
        body: JSON.stringify({
          data: [
            {
              id: "l1",
              book_id: "b1",
              member_id: "u1",
              loan_date: "2026-10-01",
              returned_date: "2026-10-15",
              status: "active",
              book: {
                id: "b1",
                title: "Overdue Book",
                author: "QA",
                copies_owned: 0,
              },
              member: { id: "u1", member_id: "M1", name: "Late Member" },
            },
          ],
          totalCount: 1,
        }),
      }),
  });
  await page.goto("/returns");
  await expect(
    page.locator("p:visible", { hasText: "Overdue Book" }).first(),
  ).toBeVisible();
  await expect(
    page.locator("span:visible", { hasText: /^Overdue$/ }).first(),
  ).toBeVisible();
});
