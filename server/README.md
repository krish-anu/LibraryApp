# Server Setup

This FastAPI backend uses PostgreSQL.

## 1. Prepare environment variables

Use two real env files:

- `.env.local` for local development
- `.env.production` for production

From the `server` directory:

```bash
cp .env.local.example .env.local
```

For production runs, use the production template instead:

```bash
cp .env.production.example .env.production
```

Real env files are ignored by Git. The `*.example` files are only safe templates.
Keep secrets in `.env.local`, `.env.production`, or your deployment secret manager.

You can connect in any of these ways:

1. `DATABASE_URL`
2. `INSTANCE_CONNECTION_NAME` + `DB_USER` + `DB_PASSWORD` + `DB_NAME`
3. `DB_HOST` + `DB_PORT` + `DB_USER` + `DB_PASSWORD` + `DB_NAME`

You still need to fill in the actual database name, user, and password before starting the API or running `seed_db.py`.

## 2. Seed the database

```bash
python seed_db.py
```

## 3. Run locally

```bash
make dev
```

Or:

```bash
ENV_FILE=.env.local uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## 4. Build or run in Docker

Build:

```bash
docker build -t libraryapp-server .
```

Run:

```bash
docker run --env-file .env.local -p 8000:8000 libraryapp-server
```

Docker Compose:

```bash
docker compose up --build
```

## 5. Health check

The root endpoint:

```text
GET /
```

should return a small JSON message.

The database connectivity check:

```text
GET /test-db
```

should return `{"result": 1}` when PostgreSQL is reachable.
