# Admin E2E Tests

These Playwright tests cover the admin portal smoke and session-protection flows.

## Install

If Playwright is not installed yet:

```bash
cd admin
npm install --save-dev @playwright/test
npx playwright install
```

## Run Unauthenticated Checks

```bash
cd admin
npx playwright test tests/e2e/admin-auth-and-smoke.spec.ts --grep unauthenticated
```

## Run Authenticated Checks

Create a storage state file after signing in as an admin, then run:

```bash
cd admin
ADMIN_E2E_AUTH_STATE=.auth/admin.json npx playwright test
```

The authenticated tests require the backend and admin portal to be configured with
valid Asgardeo admin credentials and scopes.
