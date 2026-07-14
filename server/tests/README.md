# Server Test Organization

`conftest.py` stays at the root because pytest uses it for shared fixtures.
All actual test modules are organized by purpose:

- `unit/` - schema, utility, service, config, and business-rule unit tests.
- `api/` - endpoint and API-surface tests grouped by resource.
- `integration/` - DB-backed and cross-module flows.
- `security/` - authorization, token, input validation, middleware, and rate-limit tests.
- `performance/` - performance and concurrency-oriented checks.

Verified safe local command:

```bash
TEST_DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:15432/libraryapp_test python -m pytest tests/integration/critical_flows tests/unit -q
```

The test harness uses PostgreSQL only. It refuses SQLite and refuses database
names that do not contain `test`.

Broader API/security suites include older `TestClient`-based tests and some
scaffolds that require mocked auth/HTTP setup or a live test environment.
