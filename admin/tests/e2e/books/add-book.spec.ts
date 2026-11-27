import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin can add a book to inventory", async ({ adminPage: page }) => {
  let savedBook: Record<string, unknown> | undefined;
  await mockAdminApis(page, {
    "GET /api/books": (route) => route.fulfill({
      json: { data: savedBook ? [savedBook] : [], totalCount: savedBook ? 1 : 0 },
    }),
    "POST /api/books": (route) => {
      savedBook = { id: "b-new", ...route.request().postDataJSON() };
      return route.fulfill({ status: 201, json: { data: savedBook } });
    },
  });
  await page.goto("/books");
  await page.getByRole("button", { name: /add new book/i }).click();
  const form = page.getByRole("dialog");
  await form.getByRole("button", { name: "Add Book", exact: true }).click();
  await expect(form.locator("input:invalid")).toHaveCount(2);
  await form.getByLabel("Title").fill("New Inventory Book");
  await form.getByLabel("Author").fill("QA Author");
  await form.getByLabel("Copies Owned").fill("3");
  await form.getByRole("button", { name: "Add Book", exact: true }).click();

  await expect(form).toBeHidden();
  await expect(page.getByRole("button", { name: "Edit New Inventory Book" })).toBeVisible();
  expect(savedBook).toMatchObject({
    title: "New Inventory Book",
    author: "QA Author",
    copies_owned: 3,
  });
});
