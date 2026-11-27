import { expect, mockAdminApis, test } from "../admin-fixture";

test("book deletion requires explicit confirmation", async ({ adminPage: page }) => {
  const book = { id: "b1", title: "Disposable Book", author: "QA", copies_owned: 1 };
  let deleted = false;
  await mockAdminApis(page, {
    "GET /api/books": (route) => route.fulfill({
      json: { data: deleted ? [] : [book], totalCount: deleted ? 0 : 1 },
    }),
    "DELETE /api/books/b1": (route) => {
      deleted = true;
      return route.fulfill({ json: { success: true } });
    },
  });
  await page.goto("/books");
  page.once("dialog", async (dialog) => {
    expect(dialog.type()).toBe("confirm");
    await dialog.dismiss();
  });
  const deleteButton = page.getByRole("button", { name: "Delete Disposable Book" });
  await deleteButton.click();
  await expect(deleteButton).toBeVisible();
  expect(deleted).toBe(false);

  page.once("dialog", (dialog) => dialog.accept());
  await deleteButton.click();
  await expect(deleteButton).toBeHidden();
  expect(deleted).toBe(true);
});
