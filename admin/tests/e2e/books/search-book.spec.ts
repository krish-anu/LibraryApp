import { expect, mockAdminApis, test } from "../admin-fixture";

test("admin can search and filter books", async ({ adminPage: page }) => {
  await mockAdminApis(page, {
    "GET /api/books": (route) => {
      const query = new URL(route.request().url()).searchParams;
      const matches = query.get("search") === "qa" && query.get("status") === "available";
      const book = { id: "b1", title: "QA Search Result", author: "QA", copies_owned: 1 };
      return route.fulfill({
        json: { data: matches ? [book] : [], totalCount: matches ? 1 : 0 },
      });
    },
  });
  await page.goto("/books");
  await expect(page.locator("p:visible", { hasText: /^No books found$/ })).toBeVisible();
  const search = page.waitForRequest((request) => {
    const url = new URL(request.url());
    return url.pathname === "/api/books" && url.searchParams.get("search") === "qa";
  });
  await page.getByPlaceholder("Search books...").fill("qa");
  await search;
  await page.getByRole("combobox", { name: "Filter by availability" }).selectOption("available");
  await expect(page.getByRole("button", { name: "Edit QA Search Result" })).toBeVisible();
});
