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

Full local server suite, excluding external live-login checks:

```bash
make test-server-local
```

Live Asgardeo credential-login suite:

```bash
make test-server-live-auth
```

This logs in through `/auth/login/credentials`, obtains a real Asgardeo access
token, verifies scopes through `/auth/debug/identity`, and uses that bearer
token against protected API routes. It requires these values in environment,
`server/.env.test`, `server/.env.local`, `admin/.env.local`, or
`admin/.env.e2e.local`:

```env
ASGARDEO_BASE_URL=
ASGARDEO_PUBLIC_CLIENT_ID=
ASGARDEO_INTROSPECTION_CLIENT_ID=
ASGARDEO_INTROSPECTION_CLIENT_SECRET=
E2E_ADMIN_EMAIL=
E2E_ADMIN_PASSWORD=
E2E_ADMIN_SUBJECT=
E2E_MEMBER_EMAIL=
E2E_MEMBER_PASSWORD=
```

`E2E_ADMIN_SUBJECT` is optional. If it is not set, the live test uses the
subject returned by `/auth/login/credentials` for that run. In production-like
environments, prefer real Asgardeo admin group/role claims and configure
`ADMIN_GROUPS`.

Run local plus live server coverage:

```bash
make test-server-all
```

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
