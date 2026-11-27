import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin can edit an existing book", async ({ adminPage: page }) => {
  let sampleBook = {
    id: "b1",
    title: "QA Book",
    author: "QA Author",
    category: "QA",
    description: "Test",
    rating: 4,
    publication_year: 2024,
    copies_owned: 2,
    image: "",
    language: "English",
    pages: 200,
    rating_count: 1,
  };
  await mockAdminApis(page, {
    "/api/books": async (route) => route.fulfill({
      contentType: "application/json",
      body: JSON.stringify({ data: [sampleBook], totalCount: 1 }),
    }),
    "GET /api/books/b1": async (route) => route.fulfill({
      contentType: "application/json",
      body: JSON.stringify({ data: sampleBook }),
    }),
    "PUT /api/books/b1": (route) => {
      sampleBook = { ...sampleBook, ...route.request().postDataJSON() };
      return route.fulfill({ json: { data: sampleBook } });
    },
  });
  await page.goto("/books");
  await expect(page.locator("p:visible", { hasText: "QA Book" }).first()).toBeVisible();
  await page.locator('button[aria-label="Edit QA Book"]:visible').click();
  const form = page.getByRole("dialog");
  await expect(form.getByLabel("Title")).toHaveValue("QA Book");
  await expect(form.getByText("Loading latest book details...")).toBeHidden();
  await form.getByLabel("Title").fill("Updated QA Book");
  await form.locator('button[type="submit"]').click();
  await expect(form).toBeHidden();
  await expect(page.getByRole("button", { name: "Edit Updated QA Book" })).toBeVisible();
  expect(sampleBook.title).toBe("Updated QA Book");
});
