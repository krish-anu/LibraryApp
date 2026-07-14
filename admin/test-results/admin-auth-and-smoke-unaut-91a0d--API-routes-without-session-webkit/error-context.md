# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: admin-auth-and-smoke.spec.ts >> unauthenticated admin protection >> returns JSON 401 for protected API routes without session
- Location: tests/e2e/admin-auth-and-smoke.spec.ts:13:7

# Error details

```
TypeError: (0 , _test.expect)(...).toHaveHeader is not a function
```

# Test source

```ts
  1  | import { expect, test } from "@playwright/test";
  2  | 
  3  | const authStatePath = process.env.ADMIN_E2E_AUTH_STATE;
  4  | 
  5  | test.describe("unauthenticated admin protection", () => {
  6  |   test("redirects protected pages to login", async ({ page }) => {
  7  |     await page.goto("/dashboard");
  8  | 
  9  |     await expect(page).toHaveURL(/\/login/);
  10 |     await expect(page.getByRole("heading", { name: "Library Admin" })).toBeVisible();
  11 |   });
  12 | 
  13 |   test("returns JSON 401 for protected API routes without session", async ({ request }) => {
  14 |     const response = await request.get("/api/books");
  15 | 
  16 |     expect(response.status()).toBe(401);
> 17 |     await expect(response).toHaveHeader("content-type", /application\/json/);
     |                            ^ TypeError: (0 , _test.expect)(...).toHaveHeader is not a function
  18 |     expect(await response.json()).toEqual({ error: "Unauthorized" });
  19 |   });
  20 | });
  21 | 
  22 | test.describe("authenticated admin smoke", () => {
  23 |   test.use(authStatePath ? { storageState: authStatePath } : {});
  24 | 
  25 |   test.beforeEach(() => {
  26 |     test.skip(
  27 |       !authStatePath,
  28 |       "Set ADMIN_E2E_AUTH_STATE to a Playwright storage state file for authenticated admin tests.",
  29 |     );
  30 |   });
  31 | 
  32 |   test("loads dashboard, primary navigation, and notification shell", async ({ page }) => {
  33 |     await page.goto("/dashboard");
  34 | 
  35 |     await expect(page.getByRole("heading", { name: /dashboard/i })).toBeVisible();
  36 |     await expect(page.getByRole("navigation")).toBeVisible();
  37 |     await expect(page.getByRole("link", { name: /books/i })).toBeVisible();
  38 |     await expect(page.getByRole("link", { name: /users/i })).toBeVisible();
  39 |     await expect(page.getByRole("link", { name: /fines/i })).toBeVisible();
  40 |   });
  41 | 
  42 |   test("books page supports search, filters, pagination, and add modal", async ({ page }) => {
  43 |     await page.goto("/books");
  44 | 
  45 |     await expect(page.getByRole("heading", { name: "Book Inventory" })).toBeVisible();
  46 |     await page.getByPlaceholder("Search books...").fill("qa");
  47 |     await page.getByRole("combobox").first().selectOption("available");
  48 |     await page.getByRole("button", { name: /add new book/i }).click();
  49 | 
  50 |     await expect(page.getByRole("dialog")).toBeVisible();
  51 |     await expect(page.getByLabel(/title/i)).toBeVisible();
  52 |     await expect(page.getByRole("button", { name: /save|create|add/i })).toBeVisible();
  53 |   });
  54 | 
  55 |   test("users page exposes create/edit/delete workflow controls", async ({ page }) => {
  56 |     await page.goto("/users");
  57 | 
  58 |     await expect(page.getByRole("heading", { name: "User Management" })).toBeVisible();
  59 |     await page.getByPlaceholder("Search users...").fill("member");
  60 |     await page.getByRole("button", { name: /create new user/i }).click();
  61 | 
  62 |     await expect(page.getByRole("dialog")).toBeVisible();
  63 |     await expect(page.getByLabel(/name/i)).toBeVisible();
  64 |     await expect(page.getByLabel(/email/i)).toBeVisible();
  65 |   });
  66 | 
  67 |   test("fines page validates payment management entry points", async ({ page }) => {
  68 |     await page.goto("/fines");
  69 | 
  70 |     await expect(page.getByRole("heading", { name: /fines/i })).toBeVisible();
  71 |     await page.getByRole("tab", { name: /unpaid/i }).click();
  72 |     await page.getByPlaceholder(/search/i).fill("member");
  73 |     await page.getByRole("button", { name: /create|add/i }).click();
  74 | 
  75 |     await expect(page.getByRole("dialog")).toBeVisible();
  76 |   });
  77 | 
  78 |   test("settings page saves loan/fine rules and sync controls are reachable", async ({ page }) => {
  79 |     await page.goto("/settings");
  80 | 
  81 |     await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible();
  82 |     await page.getByRole("button", { name: /fine rules/i }).click();
  83 |     await expect(page.getByLabel(/default loan period/i)).toBeVisible();
  84 |     await page.getByRole("button", { name: /sheet sync/i }).click();
  85 |     await expect(page.getByLabel(/google spreadsheet id/i)).toBeVisible();
  86 |   });
  87 | });
  88 | 
```