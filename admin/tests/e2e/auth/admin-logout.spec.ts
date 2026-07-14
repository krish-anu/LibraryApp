import { test } from "@playwright/test";

test.skip("admin logout clears session cookies", async () => {
  // Requires ADMIN_E2E_AUTH_STATE with a signed-in admin session.
});
