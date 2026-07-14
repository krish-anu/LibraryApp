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
DATABASE_URL=sqlite:///:memory: python -m pytest tests/integration/critical_flows tests/unit -q
```

Broader API/security suites include older `TestClient`-based tests and some
scaffolds that require mocked auth/HTTP setup or a live test environment.
