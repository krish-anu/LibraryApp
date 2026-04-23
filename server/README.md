# Server Setup

This FastAPI backend uses PostgreSQL.
If you're using Firebase SQL Connect, that means the backend should connect to the underlying Cloud SQL PostgreSQL instance, not to Firestore.

## 1. Prepare environment variables

From the `server` directory:

```bash
cp .env.local.example .env.local
```

For production-like runs, use the production template instead:

```bash
cp .env.production.example .env.production
```

Real env files are ignored by Git. Keep secrets in `.env.local`,
`.env.production`, or your deployment secret manager.

You can connect in any of these ways:

1. `DATABASE_URL`
2. `INSTANCE_CONNECTION_NAME` + `DB_USER` + `DB_PASSWORD` + `DB_NAME`
3. `DB_HOST` + `DB_PORT` + `DB_USER` + `DB_PASSWORD` + `DB_NAME`

For Firebase SQL / Cloud SQL, the app can infer the instance connection name from:

```env
FIREBASE_PROJECT_ID=<project-id>
FIREBASE_SQL_LOCATION=<region>
FIREBASE_SQL_INSTANCE_ID=<instance-id>
```

You still need to fill in the actual database name, user, and password before starting the API or running `seed_db.py`.

## 2. Seed the database

```bash
python seed_db.py
```

## 3. Run locally

```bash
make dev ENV_FILE=.env.local
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
ENV_FILE=.env.local docker compose up --build
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
