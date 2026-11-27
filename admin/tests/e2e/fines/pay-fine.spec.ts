import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin records a physical fine payment", async ({ adminPage: page }) => {
  let paymentBody: unknown;
  await mockAdminApis(page, {
    "/api/fines": async (route) => route.fulfill({ contentType: "application/json", body: JSON.stringify({ data: [{ id: "f1", member_id: "u1", loan_id: "l1", fine_date: "2026-11-01", fine_amount: 10, status: "unpaid", reason: "Overdue", user_name: "QA Member", user_email: "member@example.com", book_title: "Late Book", total_paid: 0, total_fine_amount: 10, user_total_due: 10 }], totalCount: 1 }) }),
    "PUT /api/fines/f1": async (route) => {
      paymentBody = route.request().postDataJSON();
      await route.fulfill({ contentType: "application/json", body: JSON.stringify({ data: { id: "f1", fine_amount: 5, status: "unpaid" }, payment: { appliedAmount: 5, remainingAmount: 5 } }) });
    },
  });
  await page.goto("/fines");
  await page.locator('button[title="Manage Payment & Renewal"]:visible').click();
  await page.getByLabel("Payment Amount (LKR)").fill("5");
  await page.getByRole("button", { name: "Record Physical Payment" }).click();
  await expect.poll(() => paymentBody).toMatchObject({ payment_amount: 5, payment_method: "physical" });
});
