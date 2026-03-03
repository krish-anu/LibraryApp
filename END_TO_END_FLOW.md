# LibraryApp End-to-End Flow Documentation

## 1. Scope

This document describes the full runtime flow of the project from authentication to daily user/admin operations, across:

- `client/` (Flutter mobile app for members)
- `server/` (FastAPI backend used by mobile app)
- `admin/` (Next.js admin portal and admin API routes)
- Shared PostgreSQL database

---

## 2. High-Level Architecture

### 2.1 Main Components

1. **Member App (`client`)**
   - Flutter + Riverpod.
   - Calls FastAPI routes in `server`.
   - Authenticates users with Asgardeo, then syncs user into local DB through backend.

2. **Member Backend (`server`)**
   - FastAPI + SQLAlchemy.
   - Exposes core library APIs: auth sync, books, loans, reservations, favorites, user profile, settings.
   - Creates/ensures core DB schema defaults at startup.

3. **Admin Portal (`admin`)**
   - Next.js App Router + server-side API routes (`admin/app/api/*`).
   - Uses PKCE-based Asgardeo login with cookie session.
   - Reads/writes PostgreSQL directly via `admin/lib/db.ts`.
   - Handles admin workflows: dashboard, book/user management, settings, fines, renewal, manual physical fine payments.

4. **Database**
   - PostgreSQL tables include `users`, `books`, `loans`, `reservations`, `fines`, `fine_payments`, `settings`, `interactions`, etc.
   - Both `server` and `admin` operate on the same DB.

### 2.2 Request Paths

1. Member app -> FastAPI -> PostgreSQL
2. Admin UI -> Next.js API routes -> PostgreSQL
3. Both member and admin auth integrate with Asgardeo

---

## 3. Startup and Initialization Flow

### 3.1 FastAPI (`server/app/main.py`)

On server startup (lifespan):

1. Creates SQLAlchemy metadata tables.
2. Ensures user profile columns exist (`phone`, `address`, `profile_image`, timestamps, etc.).
3. Ensures a default settings row exists (loan period, fine rates, thresholds).
4. Ensures fine/fine payment columns/tables exist.
5. Mounts `client/assets` at `/assets`.
6. Registers routers:
   - `/auth`, `/books`, `/loans`, `/categories`, `/favorites`, `/users`, `/reservations`, `/settings`, base routes.

### 3.2 Admin API Runtime

Admin API routes run lazy infrastructure checks when needed, especially for fines:

1. `ensureFineInfrastructure()` in `admin/lib/fines.ts` migrates/normalizes fine-related columns.
2. `syncOverdueLoanFines()` computes overdue fines from active loans and settings.
3. This sync runs before listing fines (`GET /api/fines`) so admin table reflects current overdue state.

---

## 4. Authentication Flows

### 4.1 Member (Flutter) Authentication

### Login flow

1. User logs in from Flutter (`asgardeo_direct_provider.dart`).
2. App requests token from Asgardeo (`password` grant).
3. Access/refresh/ID tokens saved in `SharedPreferences`.
4. App fetches Asgardeo userinfo.
5. App calls `POST /auth/login` (FastAPI) with access token.
6. FastAPI verifies token via Asgardeo userinfo endpoint and upserts local `users` row (`id = sub`, `member_id = sub`).
7. App uses authenticated state and opens bottom-tab app.

### Register flow

1. Flutter opens Asgardeo self-service portal in browser.
2. User returns and logs in.
3. Local DB user is created on first successful `/auth/login` sync.

### Logout flow

1. Flutter calls backend `/auth/logout` to revoke token.
2. If backend revoke fails, app falls back to direct revoke.
3. Local tokens are cleared and auth state resets.

### 4.2 Admin Authentication (PKCE)

1. Login page button -> `GET /api/auth/login`.
2. Server generates PKCE verifier/challenge + `state`, stores cookies, redirects to Asgardeo authorize endpoint.
3. Asgardeo redirects to `/api/auth/callback/asgardeo`.
4. Callback validates `state`, exchanges authorization code for tokens, fetches userinfo, sets cookies:
   - `library_session` (access token, httpOnly)
   - `library_id_token` (for logout, httpOnly)
   - `library_user` (user payload for UI hydration)
5. Redirect to `/dashboard`.
6. `middleware.ts` protects all non-public pages and APIs by checking `library_session`.

---

## 5. Member App End-to-End User Flow

### 5.1 App Entry and Tab State

1. `main.dart` shows:
   - `Login` if not authenticated
   - `BottomNav` if authenticated
2. `BottomNav` has 5 tabs:
   - Home, Search, Borrowed, WishList, Profile
3. On build, `memberId` is resolved from Asgardeo `sub` (fallback to local current user id) and injected into:
   - `LoansNotifier`
   - `FavoritesNotifier`

### 5.2 Home -> Browse Books

1. Home viewmodel loads:
   - all books (`GET /books`)
   - categories (`GET /categories`)
2. UI shows trending/recommended subsets from loaded list.

### 5.3 Search Tab

1. Search loads all books from backend.
2. Local filtering/sorting by query/category/author.
3. When Search tab becomes active, UI auto-opens search mode and autofocuses search input.

### 5.4 Wishlist (Favorites)

1. Favorites notifier loads:
   - `GET /favorites/{member_id}`
   - `GET /favorites/{member_id}/ids`
2. Empty state shows **Browse Books** button.
3. Button switches bottom-nav index to Search tab (index `1`).
4. Add/remove favorite uses:
   - `POST /favorites/{member_id}/{book_id}`
   - `DELETE /favorites/{member_id}/{book_id}`

### 5.5 Book Details -> Borrow / Reserve

### Borrow flow

1. User taps borrow in book details.
2. App calls `POST /loans/borrow?book_id=...&member_id=...`.
3. Backend validates:
   - user exists
   - user has phone and address
   - not already borrowed same book
   - max books per user not exceeded
   - unpaid-fine threshold policy (if enabled in settings)
   - copies available
4. On success:
   - loan row created (`returned_date` used as due date)
   - `copies_owned` decremented

### Reserve flow

1. App calls `POST /reservations`.
2. Backend prevents duplicate active reservations and reserving already-borrowed same book.
3. Reservation created with pending status.

### 5.6 Borrowed Tab

1. Loads active loans by member: `GET /loans/active?member_id=...`
2. Loads member reservations: `GET /reservations/member/{member_id}`
3. Return book: `POST /loans/return/{loan_id}`
   - increments copies
   - deletes loan record
4. Renew from member app: `POST /loans/renew/{loan_id}`
   - returns `403` unless admin header is present
   - user is instructed renewal is admin-handled

### 5.7 Profile Flow

1. Profile viewmodel first tries Asgardeo session user.
2. Loads profile/stats from:
   - `GET /users/{id}`
   - `GET /users/{id}/stats`
3. Update profile: `PUT /users/{id}`.
4. Sign-out clears local tokens and current user provider.

---

## 6. Admin Portal End-to-End Flow

### 6.1 Dashboard

`GET /api/dashboard` returns:

1. user count
2. total inventory
3. unpaid fine totals/count
4. average checkout duration
5. top borrowed books
6. recent fines

### 6.2 Books Management

Routes:

1. `GET /api/books` (pagination/filter/search/status)
2. `POST /api/books`
3. `GET /api/books/[id]`
4. `PUT /api/books/[id]`
5. `DELETE /api/books/[id]`

Behavior notes:

1. Handles both schema variants (`author` text or `author_id` relation).
2. Supports image fields and inventory counts.

### 6.3 User Management

Routes:

1. `GET /api/users` (list/filter)
2. `POST /api/users`
3. `GET /api/users/[id]`
4. `PUT /api/users/[id]`
5. `DELETE /api/users/[id]`

### 6.4 Settings Management

Routes:

1. `GET /api/settings`
2. `PUT /api/settings`

Settings drive:

1. loan period
2. max books/user
3. grace days
4. fine rate and cap
5. borrow blocking threshold
6. notification flags

### 6.5 Fines and Penalties (Core Admin Workflow)

### Fine listing and auto-sync

1. `GET /api/fines` first runs:
   - `ensureFineInfrastructure()`
   - `syncOverdueLoanFines()`
2. Overdue sync computes fine per overdue loan cycle:
   - cycle key = `loan_id + due_date`
   - amount = `min(overdue_days * daily_fine_rate, max_fine_cap)`
   - subtracts already recorded payments in `fine_payments`
   - stores remaining due in `fines.fine_amount`
3. Returns enriched table data:
   - user/book refs
   - payment summary (`total_paid`, `payment_count`)
   - user total due
   - computed total fine amount

### Manual fine creation

1. `POST /api/fines`
2. Inserts fine with status `unpaid`.

### Fine payment (physical only)

1. Admin opens **Manage Fine Payment & Renewal** modal.
2. Payment action calls `PUT /api/fines/[id]` with `payment_amount` and `payment_method=physical`.
3. API:
   - clamps applied payment to current outstanding
   - decreases `fines.fine_amount` (remaining due)
   - marks `paid` only when remaining reaches 0
   - writes payment ledger row in `fine_payments` (`handled_by: "admin"`)
4. UI refreshes table and shows updated remaining due.

### Waive and delete

1. Waive: `PUT /api/fines/[id]` status=`waived`
2. Delete: `DELETE /api/fines/[id]` (also deletes payment rows for that fine)

---

## 7. Renewal and Fine Business Rules

Admin renewal endpoint: `POST /api/loans/[id]/renew`

1. Renewal is admin-only.
2. Renewal extension is fixed at **14 days** (`ADMIN_RENEWAL_DAYS = 14`).
3. Due date update logic:
   - if current due date is in future: extend from existing due date
   - else: extend from current date
4. Fine behavior on renewal:
   - if renewed before due date: no overdue fine created
   - if renewed after due date: overdue fine is created/updated for days late before renewal
5. After renewal, fine-free period continues until the new due date; overdue fines start only after that new due date passes.

---

## 8. Currency and Payment Policy

1. Admin currency formatting uses `LKR` (`formatCurrency` in `admin/lib/utils.ts`).
2. Fine payment method is restricted to **physical** payments only.
3. All fine payment records are admin-handled and tracked in `fine_payments`.

---

## 9. Key Tables and Relationships

1. `users`: member identity/profile (`id`, `member_id`, contact info)
2. `books`: catalog + inventory
3. `loans`: active borrowing records (`returned_date` is used as due date in this project flow)
4. `reservations`: reserve queue by member/book
5. `fines`: current due amount per fine cycle + status
6. `fine_payments`: payment ledger (partial/full, method, notes, handled_by)
7. `interactions`: likes and engagement (favorites, trending/recommendations)
8. `settings`: runtime business configuration

---

## 10. Important End-to-End Scenarios

### Scenario A: On-time borrow and return (no fine)

1. Member borrows a book.
2. Loan due date is set from settings.
3. Member/admin returns before overdue.
4. Loan removed and copies restored.
5. No overdue fine appears.

### Scenario B: Overdue loan and partial fine payment

1. Loan passes due date.
2. Admin opens fines page; overdue sync generates/updates unpaid fine.
3. Admin collects partial physical payment (e.g., pays 4 out of 8).
4. `fines.fine_amount` decreases to remaining amount.
5. `fine_payments` stores payment record.
6. Additional payment later can settle remainder and mark fine as paid.

### Scenario C: Admin renewal

1. Admin triggers loan renewal from fines modal.
2. If overdue exists, fine is generated/updated for elapsed overdue period.
3. Loan due date extends by 14 days.
4. No new overdue fine during renewed valid period.

---

## 11. API Surface Summary

### FastAPI (`server`)

1. `POST /auth/register`, `POST /auth/login`, `POST /auth/logout`, etc.
2. `GET /books`, `GET /books/trending`, `GET /books/recommended/{user_id}`
3. `GET /loans`, `GET /loans/active`, `POST /loans/borrow`, `POST /loans/return/{id}`, `POST /loans/renew/{id}`
4. `GET/POST /reservations`, `GET /reservations/member/{member_id}`
5. `GET/POST/DELETE /favorites/...`
6. `GET/PUT /users/...`
7. `GET/PUT /settings`

### Admin API (`admin/app/api`)

1. Auth: `/api/auth/login`, `/api/auth/callback/asgardeo`, `/api/auth/me`, `/api/auth/logout`
2. Dashboard: `/api/dashboard`
3. Books: `/api/books`, `/api/books/[id]`
4. Users: `/api/users`, `/api/users/[id]`
5. Fines: `/api/fines`, `/api/fines/[id]`
6. Renewal: `/api/loans/[id]/renew`
7. Settings: `/api/settings`

---

## 12. Current Practical Notes

1. The system currently uses two API layers (FastAPI for member app, Next.js API for admin) against one database.
2. Fine calculation is synchronized when admin fines list is fetched, not by a separate scheduler.
3. Loan renewal and fine payment are intentionally admin-controlled operational workflows.
4. Client-side reservation cancellation in `LoansNotifier` currently updates local state only (no backend delete endpoint is called).
