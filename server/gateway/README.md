# Kong Gateway Setup

This folder contains declarative Kong configuration for local development.

## Files

- kong.yml: declarative Kong config (DB-less mode)

## Route Mapping

Kong exposes backend APIs under the /backend prefix.

Examples:

- GET http://localhost:8080/backend/
- GET http://localhost:8080/backend/books
- GET http://localhost:8080/backend/users

The /backend prefix is stripped before forwarding to the FastAPI service.

## Run

From the server folder:

docker compose -f compose.yaml -f compose.kong.yaml up --build

## Verify

- Kong proxy: http://localhost:8080
- Kong admin API: http://localhost:8001
- Upstream service through Kong: http://localhost:8080/backend/
