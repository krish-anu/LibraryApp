# Admin Service Layer (Microservices-Oriented)

This folder contains the business logic for the admin backend, organized by domain service boundaries.

`app/api/*` now acts as an API gateway layer:

- Each route file is a thin entrypoint.
- Route files re-export handlers from `services/*`.
- Domain logic lives inside service modules, which keeps each bounded context isolated.

## Service Domains

- `identity/` - authentication and session endpoints
- `catalog/` - books and categories
- `members/` - user/member management
- `fines/` - fine lifecycle and payment processing
- `loans/` - loan renewal actions
- `config/` - platform settings
- `analytics/` - dashboard statistics
- `storage/` - Firebase Storage uploads and signed URLs

## Why This Structure

- Improves separation of concerns by domain.
- Makes each service easier to evolve independently.
- Keeps the HTTP gateway (`app/api`) stable while internal service logic can grow.
- Provides a clean migration path to fully externalized microservices later.
- Uses Firestore and Firebase Storage behind the service boundary instead of a direct SQL client.
