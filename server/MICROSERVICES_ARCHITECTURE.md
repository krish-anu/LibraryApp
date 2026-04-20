# Server Microservices Architecture

This document describes the domain-based microservices layout added under server.

## Service Boundaries

- Auth Service
  - Base routes: /auth/*
  - Entrypoint: services/auth_service/main.py
  - Routers: auth, general

- Catalog Service
  - Base routes: /books/*, /categories/*
  - Entrypoint: services/catalog_service/main.py
  - Routers: books, category, general

- Users Service
  - Base routes: /users/*
  - Entrypoint: services/users_service/main.py
  - Routers: users, general

- Circulation Service
  - Base routes: /loans/*, /reservations/*, /favorites/*
  - Entrypoint: services/circulation_service/main.py
  - Routers: loans, reservations, favorites, general

- Settings Service
  - Base routes: /settings/*
  - Entrypoint: services/settings_service/main.py
  - Routers: settings, general

## Shared Platform Layer

All services use shared modules from app/:

- Database models and session
- Token verification dependencies
- Security middleware and headers
- Startup lifecycle and schema initialization

The shared app factory now supports selecting router sets per service.

## Gateway

Kong routes traffic to each service using gateway/kong.microservices.yml.

Public gateway examples:

- /auth/* -> auth-api
- /books/* and /categories/* -> catalog-api
- /users/* -> users-api
- /loans/*, /reservations/*, /favorites/* -> circulation-api
- /settings/* -> settings-api

## Runtime

Use compose.microservices.yaml to run db + all services + Kong.
