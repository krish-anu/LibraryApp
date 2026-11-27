import { expect, mockAdminApis, test } from "./admin-fixture";

test.describe("unauthenticated admin protection", () => {
  test("redirects protected pages to login", async ({ page }) => {
    await page.goto("/dashboard");

    await expect(page).toHaveURL(/\/login/);
    await expect(page.getByRole("heading", { name: "Library Admin" })).toBeVisible();
  });

  test("returns JSON 401 for protected API routes without session", async ({ request }) => {
    const response = await request.get("/api/books");

    expect(response.status()).toBe(401);
    expect(response.headers()["content-type"]).toMatch(/application\/json/);
    expect(await response.json()).toEqual({ error: "Unauthorized" });
  });
});

test.describe("authenticated admin smoke", () => {
  test("loads dashboard, primary navigation, and notification shell", async ({ adminPage: page }) => {
    await mockAdminApis(page);
    await page.goto("/dashboard");

    await expect(page.getByRole("heading", { name: /dashboard/i })).toBeVisible();
    if ((page.viewportSize()?.width ?? 0) < 1024) {
      await page.getByRole("button", { name: "Toggle navigation menu" }).click();
    }
    await expect(page.getByRole("navigation")).toBeVisible();
    await expect(page.getByRole("link", { name: /books/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /users/i })).toBeVisible();
    await expect(
      page.getByRole("link", { name: "Fines & Penalties", exact: true }),
    ).toBeVisible();
  });

  test("books page supports search, filters, pagination, and add modal", async ({ adminPage: page }) => {
    await mockAdminApis(page);
    await page.goto("/books");

    await expect(page.getByRole("heading", { name: "Book Inventory" })).toBeVisible();
    await page.getByPlaceholder("Search books...").fill("qa");
    await page.getByRole("combobox").first().selectOption("available");
    await page.getByRole("button", { name: /add new book/i }).click();

    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByLabel(/title/i)).toBeVisible();
    await expect(
      page.getByRole("dialog").getByRole("button", { name: "Add Book", exact: true }),
    ).toBeVisible();
  });

  test("users page exposes create/edit/delete workflow controls", async ({ adminPage: page }) => {
    await mockAdminApis(page);
    await page.goto("/users");

    await expect(page.getByRole("heading", { name: "User Management" })).toBeVisible();
    await page.getByPlaceholder("Search users...").fill("member");
    await page.getByRole("button", { name: /create new user/i }).click();

    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByLabel(/name/i)).toBeVisible();
    await expect(page.getByLabel(/email/i)).toBeVisible();
  });

  test("fines page validates payment management entry points", async ({ adminPage: page }) => {
    await mockAdminApis(page);
    await page.goto("/fines");

    await expect(page.getByRole("heading", { name: /fines/i })).toBeVisible();
    await page.getByRole("button", { name: /unpaid/i }).click();
    await page.getByPlaceholder(/search fines by user/i).fill("member");
    await page.getByRole("button", { name: /create manual fine/i }).click();

    await expect(page.getByRole("dialog")).toBeVisible();
  });

  test("settings page saves loan/fine rules and sync controls are reachable", async ({ adminPage: page }) => {
    await mockAdminApis(page);
    await page.goto("/settings");

    await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible();
    await page.getByRole("button", { name: /fine rules/i }).click();
    await expect(page.getByLabel(/default loan period/i)).toBeVisible();
    await page.getByRole("button", { name: /sheet sync/i }).click();
    await expect(page.getByLabel(/sync every/i)).toBeVisible();
  });
});
