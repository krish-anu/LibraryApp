# Microservices Architecture

This folder contains service entrypoints for a domain-based microservices split of the backend.

## Services

- auth_service: authentication and identity endpoints
- catalog_service: books and categories
- users_service: user profile endpoints
- circulation_service: loans, reservations, favorites
- settings_service: settings endpoints

Each service uses the shared app layer (models, dependencies, security middleware) and only includes its own routers.

## Entry Points

- services.auth_service.main:app
- services.catalog_service.main:app
- services.users_service.main:app
- services.circulation_service.main:app
- services.settings_service.main:app

## Local Run

Use the dedicated stack from the server directory:

docker compose -f compose.microservices.yaml up --build

Service endpoints:

- auth-api: http://localhost:8101
- catalog-api: http://localhost:8102
- users-api: http://localhost:8103
- circulation-api: http://localhost:8104
- settings-api: http://localhost:8105
