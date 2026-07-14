SHELL := /bin/bash

SERVER_TEST_DATABASE_URL ?= postgresql+psycopg2://postgres:postgres@localhost:15432/libraryapp_test
ADMIN_E2E_AUTH_STATE ?= .auth/admin.json

.PHONY: test test-server test-server-all test-client test-admin test-admin-unauth test-admin-auth-state test-admin-authenticated

test: test-server test-client test-admin

test-server:
	cd server && TEST_DATABASE_URL="$(SERVER_TEST_DATABASE_URL)" python -m pytest tests/integration/critical_flows tests/unit -q

test-server-all:
	cd server && TEST_DATABASE_URL="$(SERVER_TEST_DATABASE_URL)" python -m pytest tests -q

test-client:
	cd client && flutter test

test-admin: test-admin-unauth
	@if [ -f "admin/$(ADMIN_E2E_AUTH_STATE)" ]; then \
		$(MAKE) test-admin-authenticated; \
	else \
		echo "Skipping authenticated admin tests: admin/$(ADMIN_E2E_AUTH_STATE) not found."; \
		echo "Create it with: make test-admin-auth-state"; \
	fi

test-admin-unauth:
	@if [ ! -x admin/node_modules/.bin/playwright ]; then \
		echo "Skipping admin Playwright tests: @playwright/test is not installed."; \
		echo "Install with: cd admin && npm install --save-dev @playwright/test && npx playwright install"; \
	else \
		cd admin && ./node_modules/.bin/playwright test tests/e2e/admin-auth-and-smoke.spec.ts --grep unauthenticated; \
	fi

test-admin-auth-state:
	@if [ ! -x admin/node_modules/.bin/playwright ]; then \
		echo "Cannot create admin auth state: @playwright/test is not installed."; \
		echo "Install with: cd admin && npm install --save-dev @playwright/test && npx playwright install"; \
		exit 1; \
	fi
	cd admin && ./node_modules/.bin/playwright test tests/e2e/auth/save-admin-auth-state.spec.ts --project=chromium

test-admin-authenticated:
	@if [ ! -x admin/node_modules/.bin/playwright ]; then \
		echo "Cannot run admin Playwright tests: @playwright/test is not installed."; \
		echo "Install with: cd admin && npm install --save-dev @playwright/test && npx playwright install"; \
		exit 1; \
	fi
	cd admin && ADMIN_E2E_AUTH_STATE="$(ADMIN_E2E_AUTH_STATE)" ./node_modules/.bin/playwright test
