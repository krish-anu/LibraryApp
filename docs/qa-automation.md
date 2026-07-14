# QA Automation Pack

This repo now includes automation assets that map back to
`docs/qa-test-suite.md`.

## Backend API

High-priority API/business-rule tests:

```bash
cd server
DATABASE_URL=sqlite:///:memory: python -m pytest tests/integration/critical_flows/test_qa_critical_flows.py tests/unit -q
```

Current note: the existing `TestClient` fixture starts the FastAPI lifespan. In
this local environment the suite can hang during app startup before executing
tests; existing tests show the same behavior. If that happens, disable or mock
the sheet-sync scheduler in the test fixture before running the full suite.

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
