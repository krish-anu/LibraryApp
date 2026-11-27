import { defineConfig, devices } from "@playwright/test";
import { randomBytes } from "node:crypto";

const baseURL = new URL(process.env.ADMIN_BASE_URL || "http://127.0.0.1:3100");
const useExistingServer = Boolean(process.env.PLAYWRIGHT_SKIP_WEB_SERVER);

if (baseURL.protocol !== "http:" || !["localhost", "127.0.0.1"].includes(baseURL.hostname)) {
  throw new Error("Admin browser tests require an isolated local HTTP server.");
}
if (useExistingServer && !process.env.PLAYWRIGHT_ADMIN_SESSION_SECRET) {
  throw new Error("Set PLAYWRIGHT_ADMIN_SESSION_SECRET to the signing key of the isolated test server.");
}
const sessionSecret =
  process.env.PLAYWRIGHT_ADMIN_SESSION_SECRET ?? randomBytes(32).toString("hex");
process.env.PLAYWRIGHT_ADMIN_SESSION_SECRET = sessionSecret;

export default defineConfig({
  testDir: "./tests/e2e",
  timeout: 30_000,
  expect: {
    timeout: 5_000,
  },
  fullyParallel: true,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: baseURL.origin,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "firefox",
      use: { ...devices["Desktop Firefox"] },
    },
    {
      name: "webkit",
      use: { ...devices["Desktop Safari"] },
    },
    {
      name: "mobile-chrome",
      use: { ...devices["Pixel 5"] },
    },
  ],
  webServer: useExistingServer
    ? undefined
    : {
        command: `npm run dev -- --hostname ${baseURL.hostname} --port ${baseURL.port || 80}`,
        url: baseURL.origin,
        env: {
          ADMIN_SESSION_SECRET: sessionSecret,
          ASGARDEO_AUTHORIZE_ENDPOINT: "https://identity.example.test/oauth2/authorize",
          ASGARDEO_CLIENT_ID: "playwright-admin",
          NEXT_PUBLIC_APP_URL: baseURL.origin,
        },
        reuseExistingServer: false,
        timeout: 120_000,
      },
});
