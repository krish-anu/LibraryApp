# Server Setup

This FastAPI backend now uses Firebase Admin + Cloud Firestore.
It no longer needs `DATABASE_URL`, `DB_*`, or a local PostgreSQL container for normal development.

## 1. Prepare environment variables

From the `server` directory:

```bash
cp .env.example .env
```

Set these Firebase variables in `.env`:

```env
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxx@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

You can also provide `FIREBASE_SERVICE_ACCOUNT_JSON` instead of the three values above.

Important:

- Enable the Cloud Firestore API for your Firebase project before starting the app.
- Keep real secrets only in `.env`. That file is gitignored.
- `ASGARDEO_*` values are still required for authentication routes.

## 2. Run locally

```bash
make dev
```

Or:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## 3. Build or run in Docker

Build:

```bash
docker build -t libraryapp-server .
```

Run:

```bash
docker run --env-file .env -p 8000:8000 libraryapp-server
```

## 4. Health check

The root endpoint:

```text
GET /
```

should return a small JSON message.

The Firebase connectivity check:

```text
GET /test-db
```

returns backend status when Firebase Admin is configured correctly.
