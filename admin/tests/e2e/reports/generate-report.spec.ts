import { expect, mockAdminApis, test } from "../admin-fixture";

test("loan history provides searchable circulation records", async ({ adminPage: page }) => {
  await mockAdminApis(page, {
    "/api/loan-history": async (route) =>
      route.fulfill({
        contentType: "application/json",
        body: JSON.stringify({
          data: [
            {
              id: "l1",
              loan_date: "2026-10-01",
              returned_date: "2026-10-15",
              returned_at: "2026-10-14",
              returned_by: "Desk",
              status: "returned",
              book: { id: "b1", title: "History Book", author: "QA" },
              member: { id: "u1", member_id: "M1", name: "QA Member" },
            },
          ],
          totalCount: 1,
        }),
      }),
  });
  await page.goto("/loan-history");
  await expect(page.getByRole("heading", { name: "Loan History" })).toBeVisible();
  await page.getByRole("button", { name: "Returned History" }).click();
  await page.getByPlaceholder(/search by book/i).fill("History Book");
  await expect(
    page.locator("p:visible", { hasText: "History Book" }).first(),
  ).toBeVisible();
});
