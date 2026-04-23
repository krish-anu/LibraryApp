# LibraryApp

LibraryApp has three main parts:

- `server/` - FastAPI backend for books, categories, loans, reservations, favorites, users, settings, and auth.
- `client/` - Flutter mobile app.
- `admin/` - Next.js admin dashboard.

## Prerequisites

Install these before running the project:

- Python 3.11+ and `pip`
- PostgreSQL, Cloud SQL, or Firebase SQL Connect PostgreSQL access
- Flutter SDK
- Node.js 20+ and npm
- Docker, optional

## 1. Run The Backend API

From the project root:

```bash
cd server
cp .env.local.example .env.local
```

Edit `server/.env.local` and fill in your real values. At minimum, configure:

- Database: `DATABASE_URL`, or `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME`
- Asgardeo: `ASGARDEO_BASE_URL`
- Firebase service account values if you use Firebase features

Install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Seed the database:

```bash
python seed_db.py
```

Start the API:

```bash
make dev ENV_FILE=.env.local
```

The API runs at:

```text
http://127.0.0.1:8000
```

Check that it works:

```bash
curl http://127.0.0.1:8000/
curl http://127.0.0.1:8000/test-db
```

## 2. Run The Flutter Mobile App

Open a new terminal from the project root:

```bash
cd client
flutter pub get
```

Run on Android emulator:

```bash
flutter run \
  --dart-define=SERVER_URL=http://10.0.2.2:8000 \
  --dart-define=ASGARDEO_CLIENT_ID=1O70sZaVwlin70uGYeJlfKhvv2sa \
  --dart-define=ASGARDEO_BASE_URL=https://api.eu.asgardeo.io/t/orgd2ib6
```

Run on a physical Android device using USB:

```bash
adb reverse tcp:8000 tcp:8000
flutter run \
  --dart-define=SERVER_URL=http://127.0.0.1:8000 \
  --dart-define=ASGARDEO_CLIENT_ID=1O70sZaVwlin70uGYeJlfKhvv2sa \
  --dart-define=ASGARDEO_BASE_URL=https://api.eu.asgardeo.io/t/orgd2ib6
```

Run on a physical device over the same Wi-Fi network:

```bash
flutter run \
  --dart-define=SERVER_URL=http://YOUR_COMPUTER_IP:8000 \
  --dart-define=ASGARDEO_CLIENT_ID=1O70sZaVwlin70uGYeJlfKhvv2sa \
  --dart-define=ASGARDEO_BASE_URL=https://api.eu.asgardeo.io/t/orgd2ib6
```

Replace `YOUR_COMPUTER_IP` with your computer's local IP address, for example `192.168.1.20`.

You can also use the Flutter Makefile:

```bash
make run
```

Use the full `flutter run --dart-define=SERVER_URL=...` command above when the mobile app cannot reach the backend.

## 3. Run The Admin Dashboard

Open a new terminal from the project root:

```bash
cd admin
cp .env.local.example .env.local
npm install
npm run dev
```

The admin dashboard runs at:

```text
http://localhost:3000
```

Make sure `admin/.env.local` contains:

```env
LIBRARY_API_BASE_URL=http://127.0.0.1:8000
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

Also fill in Firebase and Asgardeo values if your admin login or storage features need them.

## Docker Option For Backend

From `server/`:

```bash
docker build -t libraryapp-server .
docker run --env-file .env.local -p 8000:8000 libraryapp-server
```

Or with Docker Compose:
 
```bash
ENV_FILE=.env.local docker compose up --build
```

## Useful Commands

Backend:

```bash
cd server
source .venv/bin/activate
python -m pytest
python scripts/migrations/migrate_startup_schema.py
```

Flutter:

```bash
cd client
flutter analyze
flutter test
flutter build apk \
  --dart-define=SERVER_URL=http://YOUR_API_HOST:8000 \
  --dart-define=ASGARDEO_CLIENT_ID=1O70sZaVwlin70uGYeJlfKhvv2sa \
  --dart-define=ASGARDEO_BASE_URL=https://api.eu.asgardeo.io/t/orgd2ib6
```

Admin:

```bash
cd admin
npm run lint
npm run build
npm start
```

## Troubleshooting

If the mobile app times out while loading books:

- Android emulator should use `SERVER_URL=http://10.0.2.2:8000`.
- Physical Android with USB should run `adb reverse tcp:8000 tcp:8000` and use `SERVER_URL=http://127.0.0.1:8000`.
- Physical device over Wi-Fi should use your computer IP, for example `SERVER_URL=http://192.168.1.20:8000`.
- Confirm the API is running with `curl http://127.0.0.1:8000/`.
- Confirm the backend database is reachable with `curl http://127.0.0.1:8000/test-db`.

If backend protected routes return `401` or `503`:

- Check that the Flutter app has a valid Asgardeo access token.
- Check `ASGARDEO_BASE_URL` in `server/.env.local`.
- Make sure the backend can reach the Asgardeo userinfo endpoint.

If the server cannot start:

- Check the database values in `server/.env.local`.
- Make sure PostgreSQL or Cloud SQL is running and reachable.
- Run `python seed_db.py` after database setup.

