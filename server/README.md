# Server Docker Setup

This backend can run either:

- against your existing external PostgreSQL database
- or with a local PostgreSQL container via Docker Compose

## Files

- `Dockerfile`: production-style image for the FastAPI backend
- `compose.yaml`: local backend + PostgreSQL stack
- `.env.example`: environment variables used by the backend

## 1. Prepare environment variables

From the `server` directory:

```bash
cp .env.example .env
```

Update the values in `.env` as needed.

Notes:

- `DATABASE_URL` is optional. If set, it overrides the split `DB_*` variables.
- For the included `compose.yaml`, the API is forced to use the local `db` service with `sslmode=disable`.
- For external PostgreSQL or Supabase, keep `DB_SSLMODE=require` or provide a full `DATABASE_URL`.

## 1.1 Run schema migration script

Before starting the API, run the idempotent migration script once:

```bash
python scripts/migrations/migrate_startup_schema.py
```

Or via Make:

```bash
make migrate
```

## 2. Run with Docker Compose

This starts:

- `api` on `http://localhost:8000`
- `db` on `localhost:5432`

```bash
docker compose up --build
```

To run in the background:

```bash
docker compose up --build -d
```

To stop:

```bash
docker compose down
```

To stop and remove the database volume:

```bash
docker compose down -v
```

## 2.1 Run with Kong Gateway

Use the Kong overlay file to keep gateway support optional and non-breaking.

From the `server` directory:

```bash
docker compose -f compose.yaml -f compose.kong.yaml up --build
```

This starts:

- API on `http://localhost:8000`
- Kong proxy on `http://localhost:8080`
- Kong admin API on `http://localhost:8001`

Request flow through Kong uses `/backend` as the public prefix and strips it before proxying to FastAPI.

Examples:

```text
GET http://localhost:8080/backend/
GET http://localhost:8080/backend/books
GET http://localhost:8080/backend/users
```

Kong configuration files live in `gateway/`:

- `gateway/kong.yml`
- `gateway/README.md`

## 2.2 Run in Microservices Mode (with Kong)

This mode runs split backend services and routes traffic through Kong.

From the `server` directory:

```bash
docker compose -f compose.microservices.yaml up --build
```

This starts:

- `auth-api` (internal)
- `catalog-api` (internal)
- `users-api` (internal)
- `circulation-api` (internal)
- `settings-api` (internal)
- `db` on `localhost:5432`
- Kong proxy on `http://localhost:8080`
- Kong admin API on `http://localhost:8001`

Kong microservices config:

- `gateway/kong.microservices.yml`

Example requests through Kong:

```text
GET http://localhost:8080/auth/register
GET http://localhost:8080/books
GET http://localhost:8080/users/by-member/{member_id}
GET http://localhost:8080/loans
GET http://localhost:8080/settings
```

To stop:

```bash
docker compose -f compose.microservices.yaml down
```

## 3. Run only the backend container

Use this if you already have a PostgreSQL database.

Build:

```bash
docker build -t libraryapp-server .
```

Run:

```bash
docker run --env-file .env -p 8000:8000 libraryapp-server
```

## 4. Health check

The container health check calls:

```text
GET /
```

The API root should respond with a small JSON message when the app is healthy.
