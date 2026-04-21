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
Keep real credentials only in `.env`; that file is gitignored and should not be committed. Commit only placeholder values in `.env.example`.

Notes:

- `DATABASE_URL` is optional. If set, it overrides the split `DB_*` variables.
- For the included `compose.yaml`, the API is forced to use the local `db` service with `sslmode=disable`.
- Local Compose uses `COMPOSE_DB_*` values for the containerized PostgreSQL instance, so your `.env` can still keep external/Supabase `DB_*` credentials.
- `ASGARDEO_PUBLIC_CLIENT_ID` is used by `/auth/login/credentials`.
- `ASGARDEO_M2M_CLIENT_ID` and `ASGARDEO_M2M_CLIENT_SECRET` are used by backend-managed flows such as `/auth/register`.
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
- `db` on `localhost:5433` by default

```bash
docker compose up --build
```

If you want the containerized database on a different host port, set `DB_PUBLISHED_PORT` in `.env`.
If you want to change the local Compose database credentials or DB name, set `COMPOSE_DB_USER`, `COMPOSE_DB_PASSWORD`, and `COMPOSE_DB_NAME`.

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

## 2.1 Run in Microservices Mode

This mode runs split backend services directly, without an API gateway.

From the `server` directory:

```bash
docker compose -f compose.microservices.yaml up --build
```

This starts:

- `auth-api` on `http://localhost:8101`
- `catalog-api` on `http://localhost:8102`
- `users-api` on `http://localhost:8103`
- `circulation-api` on `http://localhost:8104`
- `settings-api` on `http://localhost:8105`
- `db` on `localhost:5433` by default

Example requests:

```text
GET http://localhost:8101/auth/register
GET http://localhost:8102/books
GET http://localhost:8103/users/by-member/{member_id}
GET http://localhost:8104/loans
GET http://localhost:8105/settings
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
