# Server Microservices Architecture

This document describes the domain-based microservices layout added under server.

## Service Boundaries

- Auth Service
  - Base routes: /auth/\*
  - Entrypoint: services/auth_service/main.py
  - Routers: auth, general

- Catalog Service
  - Base routes: /books/_, /categories/_
  - Entrypoint: services/catalog_service/main.py
  - Routers: books, category, general

- Users Service
  - Base routes: /users/\*
  - Entrypoint: services/users_service/main.py
  - Routers: users, general

- Circulation Service
  - Base routes: /loans/_, /reservations/_, /favorites/\*
  - Entrypoint: services/circulation_service/main.py
  - Routers: loans, reservations, favorites, general

- Settings Service
  - Base routes: /settings/\*
  - Entrypoint: services/settings_service/main.py
  - Routers: settings, general

## Shared Platform Layer

All services use shared modules from app/:

- Database models and session
- Token verification dependencies
- Security middleware and headers
- Startup lifecycle and schema initialization

The shared app factory now supports selecting router sets per service.

## Direct Access

Services are exposed directly with host ports in compose.microservices.yaml:

- auth-api: http://localhost:8101/auth/\*
- catalog-api: http://localhost:8102/books/_ and /categories/_
- users-api: http://localhost:8103/users/\*
- circulation-api: http://localhost:8104/loans/_, /reservations/_, /favorites/\*
- settings-api: http://localhost:8105/settings/\*

## Runtime

Use compose.microservices.yaml to run db + all services.
