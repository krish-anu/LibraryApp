# QA Automation Pack

This repo now includes automation assets that map back to
`docs/qa-test-suite.md`.

## Backend API

High-priority API/business-rule tests:

```bash
cd server
TEST_DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:15432/libraryapp_test python -m pytest tests/integration/critical_flows/test_qa_critical_flows.py tests/unit -q
```

The server tests use PostgreSQL only. The database name must contain `test`.
The harness creates the test database if the PostgreSQL server is reachable and
the configured user has permission.

## Admin E2E

Files:

- `admin/playwright.config.ts`
- `admin/tests/e2e/admin-auth-and-smoke.spec.ts`
- `admin/tests/README.md`

Run:

```bash
cd admin
npx playwright test
```

Authenticated checks require `ADMIN_E2E_AUTH_STATE` to point to a signed-in
admin storage state file.

Create local E2E credentials in `admin/.env.e2e.local`:

```env
E2E_ADMIN_EMAIL=your-admin-test-email
E2E_ADMIN_PASSWORD=your-admin-test-password
E2E_MEMBER_EMAIL=your-member-test-email
E2E_MEMBER_PASSWORD=your-member-test-password
```

Generate admin auth state:

```bash
cd admin
npx playwright test tests/e2e/auth/save-admin-auth-state.spec.ts --project=chromium
```

## Flutter Mobile

Files:

- `client/test/auth_validation_test.dart`
- `client/test/book_share_link_test.dart`

Run:

```bash
cd client
flutter test
```

These cover form validation and deep-link/share utility behavior without
requiring a live backend.
