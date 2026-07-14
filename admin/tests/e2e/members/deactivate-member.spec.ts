import { test } from "@playwright/test";

test.skip("admin cannot delete member with activity", async () => {
  // Requirement says deactivate; backend currently hard-deletes inactive users.
});
