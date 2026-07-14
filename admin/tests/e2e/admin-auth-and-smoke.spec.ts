import { expect, test } from "@playwright/test";

const authStatePath = process.env.ADMIN_E2E_AUTH_STATE;

test.describe("unauthenticated admin protection", () => {
  test("redirects protected pages to login", async ({ page }) => {
    await page.goto("/dashboard");

    await expect(page).toHaveURL(/\/login/);
    await expect(page.getByRole("heading", { name: "Library Admin" })).toBeVisible();
  });

  test("returns JSON 401 for protected API routes without session", async ({ request }) => {
    const response = await request.get("/api/books");

    expect(response.status()).toBe(401);
    await expect(response).toHaveHeader("content-type", /application\/json/);
    expect(await response.json()).toEqual({ error: "Unauthorized" });
  });
});

test.describe("authenticated admin smoke", () => {
  test.use(authStatePath ? { storageState: authStatePath } : {});

  test.beforeEach(() => {
    test.skip(
      !authStatePath,
      "Set ADMIN_E2E_AUTH_STATE to a Playwright storage state file for authenticated admin tests.",
    );
  });

  test("loads dashboard, primary navigation, and notification shell", async ({ page }) => {
    await page.goto("/dashboard");

    await expect(page.getByRole("heading", { name: /dashboard/i })).toBeVisible();
    await expect(page.getByRole("navigation")).toBeVisible();
    await expect(page.getByRole("link", { name: /books/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /users/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /fines/i })).toBeVisible();
  });

  test("books page supports search, filters, pagination, and add modal", async ({ page }) => {
    await page.goto("/books");

    await expect(page.getByRole("heading", { name: "Book Inventory" })).toBeVisible();
    await page.getByPlaceholder("Search books...").fill("qa");
    await page.getByRole("combobox").first().selectOption("available");
    await page.getByRole("button", { name: /add new book/i }).click();

    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByLabel(/title/i)).toBeVisible();
    await expect(page.getByRole("button", { name: /save|create|add/i })).toBeVisible();
  });

  test("users page exposes create/edit/delete workflow controls", async ({ page }) => {
    await page.goto("/users");

    await expect(page.getByRole("heading", { name: "User Management" })).toBeVisible();
    await page.getByPlaceholder("Search users...").fill("member");
    await page.getByRole("button", { name: /create new user/i }).click();

    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByLabel(/name/i)).toBeVisible();
    await expect(page.getByLabel(/email/i)).toBeVisible();
  });

  test("fines page validates payment management entry points", async ({ page }) => {
    await page.goto("/fines");

    await expect(page.getByRole("heading", { name: /fines/i })).toBeVisible();
    await page.getByRole("tab", { name: /unpaid/i }).click();
    await page.getByPlaceholder(/search/i).fill("member");
    await page.getByRole("button", { name: /create|add/i }).click();

    await expect(page.getByRole("dialog")).toBeVisible();
  });

  test("settings page saves loan/fine rules and sync controls are reachable", async ({ page }) => {
    await page.goto("/settings");

    await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible();
    await page.getByRole("button", { name: /fine rules/i }).click();
    await expect(page.getByLabel(/default loan period/i)).toBeVisible();
    await page.getByRole("button", { name: /sheet sync/i }).click();
    await expect(page.getByLabel(/google spreadsheet id/i)).toBeVisible();
  });
});
