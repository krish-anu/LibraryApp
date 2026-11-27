import { createHmac } from "node:crypto";
import { expect, test as base, type Page, type Route } from "@playwright/test";

type ApiHandler = (route: Route, page: Page) => Promise<void> | void;

function signature(token: string, user: string, meta: string) {
  const sessionSecret = process.env.PLAYWRIGHT_ADMIN_SESSION_SECRET;
  if (!sessionSecret) {
    throw new Error("Playwright admin session signing key is missing.");
  }
  return createHmac("sha256", sessionSecret)
    .update(`${token}.${user}.${meta}`)
    .digest("base64url");
}

export const test = base.extend<{ adminPage: Page }>({
  adminPage: async ({ page, baseURL }, provide) => {
    const now = Math.floor(Date.now() / 1000);
    const token = "playwright-admin-token";
    const user = JSON.stringify({
      sub: "playwright-admin",
      email: "admin@example.com",
      name: "Playwright Admin",
    });
    const meta = JSON.stringify({ iat: now, exp: now + 3600 });
    const url = new URL(baseURL || "http://localhost:3000");
    const common = { domain: url.hostname, path: "/", sameSite: "Lax" as const };
    await page.context().addCookies([
      { name: "library_session", value: token, ...common },
      { name: "library_user", value: encodeURIComponent(user), ...common },
      { name: "library_session_meta", value: encodeURIComponent(meta), ...common },
      {
        name: "library_session_sig",
        value: signature(token, user, meta),
        ...common,
      },
    ]);
    await provide(page);
  },
});

export { expect };

export async function mockAdminApis(
  page: Page,
  handlers: Record<string, ApiHandler> = {},
) {
  await page.route("**/api/**", async (route) => {
    const request = route.request();
    const pathname = new URL(request.url()).pathname;
    const key = `${request.method()} ${pathname}`;
    const handler = handlers[key] || handlers[pathname];
    if (handler) {
      await handler(route, page);
      return;
    }

    const defaults: Record<string, unknown> = {
      "/api/auth/me": {
        authenticated: true,
        user: { sub: "playwright-admin", email: "admin@example.com" },
      },
      "/api/dashboard": {
        activeUsers: 0,
        totalBooks: 0,
        totalLoans: 0,
        pendingFines: 0,
        recentLoans: [],
        topBooks: [],
      },
      "/api/books": { data: [], totalCount: 0 },
      "/api/categories": { data: [] },
      "/api/users": { data: [], totalCount: 0 },
      "/api/fines": { data: [], totalCount: 0 },
      "/api/returns": { data: [], totalCount: 0 },
      "/api/loan-history": { data: [], totalCount: 0 },
      "/api/notifications": { data: [], unread: 0 },
      "/api/settings": {
        data: {
          loan_period_days: 14,
          max_books_per_user: 5,
          max_renewals: 1,
          grace_period_days: 2,
          daily_fine_rate: 0.5,
          max_fine_cap: 25,
          block_on_unpaid_fines: true,
          fine_threshold: 10,
          send_notifications: true,
          notification_days_before_due: 3,
          sheet_sync_enabled: false,
          sheet_sync_interval_days: 30,
        },
      },
    };
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(defaults[pathname] ?? { data: [] }),
    });
  });
}
