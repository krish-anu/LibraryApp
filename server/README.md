# Server Setup

This FastAPI backend uses PostgreSQL.
If you're using Firebase SQL Connect, that means the backend should connect to the underlying Cloud SQL PostgreSQL instance, not to Firestore.

## 1. Prepare environment variables

From the `server` directory:

```bash
cp .env.example .env
```

You can connect in any of these ways:

1. `DATABASE_URL`
2. `INSTANCE_CONNECTION_NAME` + `DB_USER` + `DB_PASSWORD` + `DB_NAME`
3. `DB_HOST` + `DB_PORT` + `DB_USER` + `DB_PASSWORD` + `DB_NAME`

For your current Firebase SQL setup, the inferred instance connection name is:

```env
INSTANCE_CONNECTION_NAME=libraryapp-eecd8:us-east4:libraryapp-eecd8-instance
DB_NAME=libraryapp-eecd8-database
```

You still need to fill in the actual database user and password before starting the API or running `seed_db.py`.

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
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## 4. Build or run in Docker

Build:

```bash
docker build -t libraryapp-server .
```

Run:

```bash
docker run --env-file .env -p 8000:8000 libraryapp-server
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
