# libraryapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Asgardeo Configuration

The mobile app no longer ships with a default Asgardeo tenant or client ID.
Provide them explicitly at launch/build time:

```bash
cd client
flutter run \
  --dart-define=ASGARDEO_CLIENT_ID=your-public-client-id \
  --dart-define=ASGARDEO_BASE_URL=https://api.eu.asgardeo.io/t/your-org
```

`ASGARDEO_BASE_URL` must be the tenant base URL only. Do not include
`/oauth2/token`, `/oauth2/authorize`, or any other endpoint suffix.

If you prefer not to retype them each time:

```bash
export ASGARDEO_CLIENT_ID=your-public-client-id
export ASGARDEO_BASE_URL=https://api.eu.asgardeo.io/t/your-org
cd client
flutter run \
  --dart-define=ASGARDEO_CLIENT_ID=$ASGARDEO_CLIENT_ID \
  --dart-define=ASGARDEO_BASE_URL=$ASGARDEO_BASE_URL
```

Optional overrides:

- `ASGARDEO_REDIRECT_URL` if your app callback URI differs from `com.example.libraryapp://callback`
- `ASGARDEO_SELF_SERVICE_PORTAL_URL` if your tenant uses a custom self-service portal URL
