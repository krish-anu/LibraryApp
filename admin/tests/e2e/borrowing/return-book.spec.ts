import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin records a book return", async ({ adminPage: page }) => {
  let returned = false;
  await mockAdminApis(page, {
    "GET /api/returns": async (route) =>
      route.fulfill({
        contentType: "application/json",
        body: JSON.stringify({
          data: returned
            ? []
            : [
                {
                  id: "l1",
                  book_id: "b1",
                  member_id: "u1",
                  loan_date: "2026-11-01",
                  returned_date: "2026-11-15",
                  status: "active",
                  book: {
                    id: "b1",
                    title: "Return Me",
                    author: "QA",
                    copies_owned: 0,
                  },
                  member: {
                    id: "u1",
                    member_id: "M1",
                    name: "QA Member",
                    email: "member@example.com",
                    phone: "0771234567",
                  },
                },
              ],
          totalCount: returned ? 0 : 1,
        }),
      }),
    "POST /api/returns/l1": async (route) => {
      returned = true;
      await route.fulfill({ contentType: "application/json", body: JSON.stringify({ status: "Returned" }) });
    },
  });
  await page.goto("/returns");
  await page.getByRole("button", { name: "Mark Returned" }).first().click();
  await expect(page.getByRole("dialog")).toBeVisible();
  await page.getByLabel("Returned by").fill("Desk Assistant");
  await page.getByRole("button", { name: "Confirm Return" }).click();
  await expect(page.getByText(/returned "Return Me"/i)).toBeVisible();
});
