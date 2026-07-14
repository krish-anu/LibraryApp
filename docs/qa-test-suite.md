# LibraryApp QA Test Suite

## Requirement Analysis Summary

Sources analyzed: root README, `server/README.md`, `admin/README.md`, FastAPI OpenAPI export, backend routers and Pydantic schemas, admin Next.js pages/services, Flutter mobile screens/viewmodels, and existing backend tests.

Testable product areas:

- Public/mobile member app: authentication, signup, home browsing, search/filter/sort, book details, favorite/wishlist, borrowing, reservations, borrowed/reserved lists, notifications, profile edit, theme/sign-out.
- Admin portal: Asgardeo admin login/session, dashboard, book inventory, category creation, image upload, user management, fines/payments, loan history/returns/renewals, notifications, blogs, videos, Google Sheet sync, settings.
- Backend API: auth, books, categories, loans, reservations, favorites, users/profile images, fines/payments, notifications/device tokens, content, content sync, settings, dashboard, health, security middleware.
- Cross-cutting: authorization scopes/admin role checks, direct object access, validation boundaries, concurrency, network interruptions, data integrity, accessibility, responsiveness, compatibility, performance, localization/timezone.

## Test Cases

### Authentication, Session, and Authorization

| Test Case ID | Module/Feature | Test Scenario | Test Case Title | Preconditions | Test Data | Test Steps | Expected Result | Test Type | Priority | Severity | Automation Candidate | Remarks or Assumptions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AUTH-001 | Mobile Login | Positive login | Sign in with valid Asgardeo credentials | Asgardeo configured; user exists | Valid username/email and password | Open mobile app; enter credentials; tap Sign In | Login succeeds, success snackbar appears, app navigates to authenticated shell/home | Functional, E2E | Critical | Blocker | Yes | Uses direct auth provider. |
| AUTH-002 | Mobile Login | Required field validation | Submit blank mobile login form | App on Sign In page | Blank username and password | Tap Sign In without input | Username/email and password validation messages appear; no API login call is made | Validation, Negative | High | Major | Yes | Client-side validation. |
| AUTH-003 | Mobile Login | Invalid credentials | Sign in with wrong password | Asgardeo reachable | Existing email with wrong password | Enter credentials; tap Sign In | Error banner is shown; user stays unauthenticated; password remains masked | Negative, Security | Critical | Critical | Yes | Error must not reveal whether account exists. |
| AUTH-004 | Mobile Login | Password visibility control | Toggle password visibility | App on Sign In page | Any password | Type password; tap show/hide icon twice | Password alternates between visible and obscured; typed value is preserved | UI/UX | Medium | Minor | Yes | Include screen-reader label check. |
| AUTH-005 | Mobile Signup | Positive registration launch | Start signup with valid required fields | Asgardeo registration flow configured | First/last name, valid email, strong password, matching confirm password | Open Sign Up; enter values; tap Sign Up | Registration flow opens; explanatory dialog appears; Go to Login returns user to Login | Functional, E2E | High | Major | Yes | Browser registration completion depends on IdP. |
| AUTH-006 | Mobile Signup | Email validation | Reject malformed email | App on Sign Up page | `abc`, `a@`, `a@b`, `a@b.c`, spaces | Enter malformed email variants; submit | Valid email message appears; submit is blocked | Validation, Boundary | High | Major | Yes | Regex allows 2-4 char TLD; confirm product expectation. |
| AUTH-007 | Mobile Signup | Password strength | Reject weak passwords | App on Sign Up page | `Short1`, `lowercase1`, `UPPERCASE1`, `NoDigitsHere` | Enter each weak password; submit | Specific password strength validation appears; submit is blocked | Validation, Security | High | Major | Yes | Backend also validates for `/auth/register`. |
| AUTH-008 | Mobile Signup | Confirm password | Reject mismatched passwords | App on Sign Up page | `Validpass1` and `Validpass2` | Fill required fields; submit | `Passwords do not match` appears; no registration request | Validation | High | Major | Yes |  |
| AUTH-009 | Mobile Signup | Optional address flow | Expand/collapse optional address fields | App on Sign Up page | Street/city/state/postal/country | Expand Add Address; type values; collapse and expand | Fields remain usable and values are included only when nonblank | UI/UX, Functional | Medium | Minor | Yes | No required validation for optional address. |
| AUTH-010 | Backend Auth | Access token sync | `/auth/login` creates local user from valid access token | Valid Asgardeo token; DB reachable | Access token with `sub`, email, names | POST `/auth/login`; query `users` table | API returns success, created flag, local user with `id=sub` and member_id=sub | API, Integration, DB | Critical | Critical | Yes | Mock Asgardeo userinfo for automation. |
| AUTH-011 | Backend Auth | Invalid access token | `/auth/login` rejects invalid token | Asgardeo reachable | Invalid token | POST `/auth/login` | 401 with `Invalid Asgardeo access token`; no user row inserted | API, Negative, Security | Critical | Critical | Yes |  |
| AUTH-012 | Backend Auth | Identity provider outage | Login sync when Asgardeo unavailable | Network to IdP unavailable | Any token | POST `/auth/login` | 503 `Unable to reach identity provider`; no local partial user | API, Error Recovery | High | Major | Yes |  |
| AUTH-013 | Backend Auth | Credential token login | `/auth/login/credentials` exchanges credentials through Asgardeo App-Native Auth | API running; Asgardeo public client configured | Valid admin/member credentials | POST `/auth/login/credentials`; use returned bearer token on `/auth/debug/identity` and protected API route | 200 response includes access token, refresh token when issued, synced local user, expected scopes, and protected route succeeds or denies based on role/scope | API, Security, Integration | Critical | Critical | Yes | Uses PKCE/app-native flow, not password grant. |
| AUTH-014 | Backend Auth | Logout token revocation | Revoke mobile token | `ASGARDEO_PUBLIC_CLIENT_ID` configured | Valid access token | POST `/auth/logout` | 200 success when Asgardeo revokes token; failure returns controlled error | API, Integration | Medium | Major | Yes | Mock revoke endpoint. |
| AUTH-015 | Admin Login | Admin login redirect | Sign in with valid admin account | Admin app configured; user in configured admin group | Admin Asgardeo user | Open `/login`; click Sign in with Asgardeo; complete callback | Session cookies set; redirected to `/dashboard`; `/api/auth/me` returns admin user | Functional, E2E | Critical | Blocker | Yes | Use test IdP tenant or mocked callback. |
| AUTH-016 | Admin Authorization | Non-admin denied | Non-admin attempts admin portal | Non-admin user authenticated at IdP | Non-admin account | Complete admin callback or access protected route | User is denied/redirected; no protected data displayed | Security, RBAC | Critical | Critical | Yes | Requires group/role claim coverage. |
| AUTH-017 | Admin Session | Protected route without session | Direct access `/dashboard` unauthenticated | No admin cookies | None | Open `/dashboard` | Redirects to `/login`; stale session cookies are cleared | Security, Session | Critical | Critical | Yes |  |
| AUTH-018 | Admin Session | API without session | Call admin API unauthenticated | No cookies | GET `/api/books` | Send request | 401 JSON `{error:"Unauthorized"}` | API, Security | Critical | Critical | Yes |  |
| AUTH-019 | Admin Session | Tampered cookie | Modify admin session payload/signature | Existing valid session | Alter `library_user` or signature | Request protected route/API | Request denied; cookies cleared for page requests | Security, Session | Critical | Critical | Yes |  |
| AUTH-020 | Authorization Scopes | Missing API scope | Authenticated user without required scope calls route | Token valid but lacks scope | Token missing `books_read` | GET `/books` | 403 missing required scope; no data returned | API, RBAC | Critical | Critical | Yes | Repeat for each scope family. |
| AUTH-021 | Authorization IDOR | Member accesses another member resource | Two member users exist | User A token; User B ID | User A GET `/users/{userB}` and `/favorites/{userB}` | 403 for subject mismatch | Security, Negative | Critical | Critical | Yes | Applies to users, favorites, loans, reservations, fines. |
| AUTH-022 | Session Expiration | Expired token/session | Existing login expires | Expired admin/mobile token | Refresh page or call protected API | App handles 401/403 by showing login/error state; no sensitive data remains visible | Session, Error Handling | Critical | Major | Yes | Expected mobile redirect behavior needs confirmation. |
| AUTH-023 | Auth Rate Limit | Brute-force protection | Exceed auth endpoint rate limit | Rate limit env enabled | More than limit requests/minute | Repeatedly POST `/auth/register` or `/auth/login/credentials` | 429 returned after configured threshold | Security, Performance | High | Major | Yes | Default values from env. |
| AUTH-024 | Admin Logout | Logout clears session | Admin logged in | Valid admin session | Click logout or GET `/api/auth/logout`; revisit dashboard | Cookies cleared; protected route redirects to login | Functional, Session | Critical | Major | Yes |  |

### Catalog, Books, Categories, Search, and Images

| Test Case ID | Module/Feature | Test Scenario | Test Case Title | Preconditions | Test Data | Test Steps | Expected Result | Test Type | Priority | Severity | Automation Candidate | Remarks or Assumptions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| CAT-001 | API Books | List books | Get all books with read scope | Seeded books exist | Token with `books_read` | GET `/books` | 200 list of books matching schema; no admin-only data | API, Functional | Critical | Critical | Yes | Backend list has no pagination. |
| CAT-002 | API Books | Create book | Admin creates valid book | Admin token | Valid title, author, category, rating 4.5, current year, copies 3 | POST `/books`; GET created ID | 201; book persists; category auto-created if missing | API, Functional, DB | Critical | Critical | Yes | Auto-create category is code behavior. |
| CAT-003 | API Books | Required fields | Create book missing title/author/category | Admin token | Blank or absent required fields | POST `/books` with each missing/blank | 422 validation error; no DB row | API, Validation, Negative | High | Major | Yes | Pydantic min length. |
| CAT-004 | API Books | Boundary values | Book numeric min/max accepted | Admin token | rating 0 and 5; pages 1 and 10000; copies 0 and 10000; publication year 0 and current+1 | POST/PUT with boundary values | Valid boundaries accepted and returned unchanged | Boundary, API | High | Major | Yes | Current year is dynamic. |
| CAT-005 | API Books | Out-of-range values | Reject invalid numeric values | Admin token | rating -0.1/5.1; pages 0/10001; copies -1/10001; future year > current+1 | POST `/books` | 422; no row inserted | Boundary, Negative | High | Major | Yes |  |
| CAT-006 | API Books | Image URL validation | Reject unsafe image URL | Admin token | `http://x`, `javascript:alert(1)`, `ftp://x`, 2049-char URL | POST/PUT book | 422; unsafe image not stored | Security, Validation | High | Major | Yes | Only `https://`, assets, `/assets`, `/books` allowed. |
| CAT-007 | API Books | Get nonexistent book | Retrieve missing book ID | Read token | `missing-book-id` | GET `/books/missing-book-id` | 404 `Book not found` | API, Negative | Medium | Major | Yes |  |
| CAT-008 | API Books | Update nonexistent book | Update missing book ID | Admin token | Valid payload | PUT `/books/missing-book-id` | 404; no category/book side effect | API, Negative | Medium | Major | Yes |  |
| CAT-009 | API Books | Delete book | Admin deletes existing book | Admin token; book has no required FK blockers | Existing book ID | DELETE `/books/{id}`; GET `/books/{id}` | 204; subsequent GET 404 | API, CRUD, DB | High | Major | Yes | Deleting books with loans may depend on FK policy. |
| CAT-010 | API Books | Unauthorized book management | Member attempts create/update/delete | Member token without manage/admin | Valid payload | POST/PUT/DELETE `/books` routes | 403; no DB mutation | Security, RBAC | Critical | Critical | Yes |  |
| CAT-011 | Book Images | Upload valid book image | Admin uploads image blob | Existing book; admin token | PNG/JPEG/WebP under size limit | PUT `/books/{id}/image` with image content-type; GET image | Book image path changes; GET returns image bytes and correct content type | API, File Upload, DB | High | Major | Yes | Test via backend and admin gateway. |
| CAT-012 | Book Images | Reject invalid image upload | Upload wrong MIME/body | Existing book; admin token | `text/plain`, empty body, oversized body | PUT image endpoint | 400/413; existing image unchanged | Security, Validation | High | Major | Yes | Uses max body middleware. |
| CAT-013 | Book Images | Delete book image | Remove uploaded image | Book has blob image | Admin token | DELETE `/books/{id}/image`; GET image | Book returned with image cleared or previous URL; image GET 404 | API, CRUD | Medium | Major | Yes |  |
| CAT-014 | Categories | List categories | Fetch categories with read scope | Categories exist | Read token | GET `/categories` | 200 list of category IDs/names/image_url | API, Functional | High | Major | Yes |  |
| CAT-015 | Categories | Create category | Admin creates unique category | Admin token | `Data Science` with optional HTTPS image | POST `/categories` | 201; ID generated as `cat_data_science`; appears in list | API, CRUD, DB | High | Major | Yes | ID generation may collide for punctuation/case. |
| CAT-016 | Categories | Duplicate category | Create same category twice | Existing category | Same name exact case | POST `/categories` | 400 `Category already exists` | API, Negative | High | Major | Yes | Case sensitivity is ambiguous. |
| CAT-017 | Categories | Category image validation | Reject unsafe category image URL | Admin token | `javascript:...`, `http://...`, 2049 chars | POST/PUT `/categories` | 422; no unsafe URL stored | Security, Validation | High | Major | Yes |  |
| CAT-018 | Categories | Delete category with books | Deleting category used by books | Category assigned to books | Existing category ID | DELETE `/categories/{id}` | Either blocked with integrity error handled or books remain consistent | API, DB Integrity | High | Critical | Yes | Requirement gap: expected behavior not specified. |
| CAT-019 | Admin Books UI | List and paginate books | Admin views book inventory pages | Admin logged in; >10 books | Seeded books | Open Books; click next/previous pagination | Table/cards show 10 per page; counters correct; buttons disabled at first/last page | UI, Functional | High | Major | Yes | Admin gateway paginates in-memory. |
| CAT-020 | Admin Books UI | Search books | Search by title/author/category/description | Admin logged in; searchable books exist | Query terms incl. case variants | Enter search term | Results filter case-insensitively; page resets to 1; no-results state appears when none match | UI, Functional | High | Major | Yes |  |
| CAT-021 | Admin Books UI | Filter books | Filter by available/not available/category | Admin logged in | Books with copies 0 and >0; categories | Select filters individually and combined | Results match copies/status and category; status badges correct | UI, Integration | High | Major | Yes |  |
| CAT-022 | Admin Books UI | Add book modal | Add book through modal | Admin logged in; categories loaded | Valid modal values; optional cover file | Click Add New Book; fill all fields; save | Modal closes; row appears; cover uploads if selected | UI, E2E | Critical | Critical | Yes | Includes gateway + backend. |
| CAT-023 | Admin Books UI | Modal validation/errors | Save invalid book in admin UI | Admin logged in | Blank title, invalid numeric values, bad URL | Submit modal | API error surfaced; modal remains open; duplicate clicks disabled while submitting | UI, Validation | High | Major | Yes | HTML number min may not cover all API limits. |
| CAT-024 | Admin Books UI | Edit latest details | Edit book fetches latest server state | Admin logged in; book changed externally | Existing book | Open edit while backend has newer values | Modal hydrates row immediately then updates with latest detail response | Integration, UI | Medium | Major | Yes | Race covered by request ref. |
| CAT-025 | Admin Books UI | Delete confirmation | Cancel and confirm delete | Admin logged in | Existing book | Click trash; cancel confirm; repeat and confirm | Cancel does nothing; confirm removes row or shows failure alert | UI, CRUD | High | Major | Yes |  |
| CAT-026 | Admin Categories UI | Create category inline | Add category from book modal | Admin logged in | New category name | Open Add Book; open category form; enter category; create | Category added to dropdown, selected in form, sorted alphabetically | UI, Functional | Medium | Minor | Yes | Duplicate error shown inline. |
| CAT-027 | Mobile Home | Load home content | Home displays trending, categories, recommended | Member logged in; API seeded | Books/categories | Open app Home | Loading then sections display; notification unread badge fetched | UI, Functional | High | Major | Yes |  |
| CAT-028 | Mobile Home | Pull-to-refresh | Refresh home data | Member logged in | Updated backend data | Pull down home list | Books/categories refresh without duplicate items or layout jump | UI, Integration | Medium | Minor | Yes |  |
| CAT-029 | Mobile Home | Category failure | Category API fails only | Member logged in; categories endpoint returns error | N/A | Open Home | Books still display; category error card with Retry Categories shown | Error Handling | Medium | Major | Yes |  |
| CAT-030 | Mobile Search | Search and focus | Open search from home | Member logged in; books exist | Search query | Tap search bar; type query | Browse screen opens, keyboard focus in search field, filtered results update | UI, Functional | High | Major | Yes |  |
| CAT-031 | Mobile Search | Sort results | Sort search results | Books with varied title/rating/year | Sort values from dropdown | Change sort option | Results reorder according to selected sort; selected value remains visible | Functional, UI | Medium | Minor | Yes | Sort rules should be confirmed. |
| CAT-032 | Mobile Search | Filter by category/author | Combine category and author filters | Books across categories/authors | Category chip and author chip | Select filters; clear to All | Results match combined filters; empty state shown when no match | Functional | High | Major | Yes |  |
| CAT-033 | Mobile Book Detail | Display metadata | View book details | Member logged in; book has full metadata | Book with image, rating, pages, language | Tap book card | Cover, availability, title, author, rating count, pages, language, category, summary display | UI, Functional | High | Major | Yes |  |
| CAT-034 | Mobile Book Detail | Share book | Use share action | Member logged in | Existing book | Tap share icon | Native share sheet opens with title/author/deep text; app remains stable on cancel | Functional, Device | Low | Minor | No | Hard to automate fully. |
| CAT-035 | Mobile Book Detail | Latest book refresh in borrow sheet | Copies changed after list load | Book list shows stale available but backend now unavailable | Open book; tap borrow | Sheet fetches latest book and switches borrow/reserve state if copies changed | Integration, Data Integrity | High | Major | Yes |  |
| CAT-036 | Static Assets | Asset path traversal | Request hidden/disallowed asset | Server serves assets | `/assets/.env`, `/assets/file.py` | GET paths | 404; no hidden or disallowed files served | Security | High | Critical | Yes | Production local assets may be disabled. |

### Loans, Returns, Reservations, Favorites, and Wishlist

| Test Case ID | Module/Feature | Test Scenario | Test Case Title | Preconditions | Test Data | Test Steps | Expected Result | Test Type | Priority | Severity | Automation Candidate | Remarks or Assumptions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| CIRC-001 | Borrow API | Borrow available book | Member borrows book with complete profile | Member has phone/address; copies >0; no blocking fines | book_id, member_id | POST `/loans/borrow?book_id=...&member_id=...` | Loan active; due date = today + loan_period_days; book copies decrement by 1; notifications created if possible | API, Functional, DB | Critical | Blocker | Yes | Uses settings default 14 if missing. |
| CIRC-002 | Borrow API | Missing phone/address | Borrow blocked until profile complete | Member missing phone and/or address | Missing phone/address combinations | POST borrow | 400 with specific message; no loan; copies unchanged | Validation, Business Rule | Critical | Critical | Yes | Mirrors mobile contact dialog. |
| CIRC-003 | Borrow API | Duplicate active loan | Borrow same book twice | Existing active loan for same member/book | Same IDs | POST borrow again | 409 duplicate borrowed message; copies unchanged | Negative, Data Integrity | Critical | Critical | Yes |  |
| CIRC-004 | Borrow API | Max books limit | Member at max active loans | Settings max_books_per_user=N; member has N active loans | New available book | POST borrow | 400 borrowing limit reached; copies unchanged | Business Rule, Boundary | Critical | Critical | Yes | Test N=1 and default 5. |
| CIRC-005 | Borrow API | Fine threshold block | Unpaid fines at/above threshold | Settings block true, threshold 10; member unpaid fines 10.00 | Available book | POST borrow | 400 blocked due to unpaid fines; includes current fines and threshold | Business Rule, Integration | Critical | Critical | Yes | Boundary: equal threshold blocks. |
| CIRC-006 | Borrow API | Fine blocking disabled | Borrow with unpaid fines when disabled | Settings `block_on_unpaid_fines=false`; unpaid fines exist | Available book | POST borrow | Loan succeeds if other rules pass | Business Rule | High | Major | Yes |  |
| CIRC-007 | Borrow API | No copies available | Borrow unavailable book | Book copies_owned=0 | book_id/member_id | POST borrow | 400 `No copies available`; no loan | Negative, Boundary | Critical | Critical | Yes |  |
| CIRC-008 | Borrow API | Missing member/book | Borrow with invalid IDs | Valid token | nonexistent book or member | POST borrow | 404 `Member not found` or `Book not found`; no side effects | Negative, API | High | Major | Yes | Member check occurs before book check. |
| CIRC-009 | Borrow API | Concurrent last-copy borrow | Two members borrow one-copy book simultaneously | Book copies=1; two eligible members | Two parallel POST borrow requests | Only one succeeds; copies never negative; loser gets controlled failure | Concurrency, Data Integrity | Critical | Critical | Yes | Current implementation may need DB locking. |
| CIRC-010 | Borrow API | Notification failure isolation | Borrow when notification service fails | Mock notification exception | Valid borrow | POST borrow | Loan still succeeds; no 500 from notification failure | Error Handling, Integration | High | Major | Yes | Code intentionally swallows notification errors. |
| CIRC-011 | Return API | Return active loan | Member/admin returns borrowed book | Active loan exists; book exists | loan_id; optional returned_by | POST `/loans/return/{loan_id}` | Loan status returned; returned_at today; returned_by stored; book copies increment | API, Functional, DB | Critical | Critical | Yes |  |
| CIRC-012 | Return API | Return same loan twice | Duplicate return submission | Loan already returned | loan_id | POST return again | 409 `Loan is already returned`; copies not incremented again | Negative, Duplicate | Critical | Critical | Yes |  |
| CIRC-013 | Return API | Return missing loan | Invalid loan ID | Valid token | missing loan_id | POST return | 404 `Loan not found` | API, Negative | Medium | Major | Yes |  |
| CIRC-014 | Return API | Return by other member | IDOR on return | Loan belongs to User A; User B token | User B POST return | 403; status/copies unchanged | Security, RBAC | Critical | Critical | Yes | Admin may return any. |
| CIRC-015 | Renew API | Renew active loan | Extend active loan | Active loan exists | loan_id | POST `/loans/renew/{loan_id}` | returned_date becomes today + loan_period_days; notification created | API, Functional | High | Major | Yes | Admin UI also uses renew from fines. |
| CIRC-016 | Renew API | Renew returned loan | Reject returned loan renewal | Loan status returned | loan_id | POST renew | 409 `Returned loans cannot be renewed` | Negative, Business Rule | High | Major | Yes |  |
| CIRC-017 | Loans API | Active loans access | Member fetches own active loans | Member has active loans | member_id query | GET `/loans/active?member_id=own` | 200 own active loans only | API, RBAC | High | Major | Yes |  |
| CIRC-018 | Loans API | Active loans without member ID | Non-admin omits member_id | Member token | None | GET `/loans/active` | 403 member_id required unless admin | API, Security | Critical | Major | Yes |  |
| CIRC-019 | Admin Loans | Loan history filter | Admin filters loan history by status | Admin token; mixed loan statuses | status `active`, `returned`, unknown | GET `/loans/history?status=...` or admin page filter | Matching rows returned and sorted; unknown status returns empty | API, UI | Medium | Minor | Yes |  |
| CIRC-020 | Reservation API | Reserve unavailable book | Member reserves book | Member not already borrowed/reserved | Reservation payload with YYYY-MM-DD | POST `/reservations` | 201 reservation with pending/status; notifications created | API, Functional, DB | High | Major | Yes | API does not require copies=0; confirm rule. |
| CIRC-021 | Reservation API | Reserve while borrowed | Member reserves book they borrowed | Existing loan same member/book | Reservation payload | POST `/reservations` | 409 return before reserving | Business Rule, Negative | High | Major | Yes | Code checks any loan, not only active. |
| CIRC-022 | Reservation API | Duplicate active reservation | Member reserves same book twice | Existing active/pending reservation | Same payload | POST reservation again | 409 `You already reserved this book` | Negative, Duplicate | High | Major | Yes | Inactive statuses allow re-reserve. |
| CIRC-023 | Reservation API | Invalid reservation date | Malformed date | Member token | `2026-99-99`, `tomorrow` | POST `/reservations` | 400 invalid format; no row inserted | Validation | Medium | Major | Yes | Expected ISO YYYY-MM-DD. |
| CIRC-024 | Reservation API | Cancel reservation | Member cancels own reservation | Existing reservation | reservation_id | DELETE `/reservations/{id}` | Reservation returned with status `Cancelled`; notification created | API, Functional | High | Major | Yes | It soft-cancels, not delete. |
| CIRC-025 | Reservation API | Cancel other member reservation | IDOR cancel | User B reservation; User A token | reservation_id | DELETE reservation | 403; status unchanged | Security, RBAC | Critical | Critical | Yes |  |
| CIRC-026 | Mobile Borrow Sheet | Borrow available book | Confirm borrow from book detail | Member logged in; profile complete; book copies>0 | Existing book | Tap book; tap Borrow; confirm | Sheet closes; success snackbar; borrowed list refreshes; copies reflect decrement | Mobile E2E | Critical | Blocker | Yes |  |
| CIRC-027 | Mobile Borrow Sheet | Required contact dialog | Borrow with missing contact | Member missing phone/address | New phone/address | Confirm borrow; fill dialog; Save & Continue | Profile updates then borrow succeeds; cancel stops borrow | Mobile, Validation, Integration | Critical | Critical | Yes |  |
| CIRC-028 | Mobile Borrow Sheet | Reserve unavailable book | Confirm reservation for copies=0 | Member logged in; book unavailable | Book ID | Tap confirm reservation | Reservation succeeds; reserved tab refreshes; success snackbar | Mobile E2E | High | Major | Yes |  |
| CIRC-029 | Mobile Borrow Sheet | Duplicate friendly error | Duplicate borrow/reserve message | Existing duplicate state | Same book | Try borrow/reserve | User-friendly duplicate snackbar shown; no crash | UI, Negative | Medium | Minor | Yes |  |
| CIRC-030 | Mobile Borrow Sheet | Interrupted workflow | Close sheet during settings/latest-book load | Slow network | Existing book | Open sheet; close before requests complete | No setState-after-dispose crash; no unintended borrow | Error Handling, Network | High | Major | Yes |  |
| CIRC-031 | Mobile My Books | Borrowed tab | Display active borrowed books and stats | Member has active/overdue/due-soon loans | Mixed due dates | Open My Books Borrowed tab | Stats and cards match active loans; due-date sorting displayed | UI, Functional | High | Major | Yes |  |
| CIRC-032 | Mobile My Books | Reserved tab | Display reservations | Member has reservations | Pending/cancelled reservations | Open Reserved tab | Reservation cards show book, reservation date, status; empty state when none | UI, Functional | Medium | Minor | Yes |  |
| CIRC-033 | Mobile My Books | Refresh/error | Refresh borrowed/reserved data | API failure then recovery | N/A | Pull refresh; tap refresh icon; simulate failure | Error/loading states shown; retry recovers data without duplicates | Error Handling | Medium | Major | Yes |  |
| CIRC-034 | Favorites API | Add favorite | Member favorites book | Member and book exist | member_id/book_id | POST `/favorites/{member_id}/{book_id}` | 200 is_favorite true; interaction row created | API, Functional, DB | High | Major | Yes |  |
| CIRC-035 | Favorites API | Idempotent favorite add | Add same favorite twice | Existing favorite | Same IDs | POST add twice | Second returns already in favorites; only one interaction row | API, Idempotency | High | Major | Yes |  |
| CIRC-036 | Favorites API | Remove favorite | Remove existing and nonexistent favorite | Existing favorite then removed | Same IDs | DELETE favorite twice | First removes; second returns not in favorites; no error | API, Idempotency | Medium | Minor | Yes |  |
| CIRC-037 | Favorites API | Favorite missing book | Add nonexistent book | Member token | missing book_id | POST favorite | 404 Book not found; no interaction | API, Negative | Medium | Major | Yes |  |
| CIRC-038 | Mobile Favorites | Favorite toggle | Toggle favorite from book detail | Member logged in; book exists | Book ID | Tap favorite icon twice | Icon/loading states update; snackbars show add/remove; wishlist reflects final state | Mobile E2E | High | Major | Yes |  |
| CIRC-039 | Mobile Wishlist | Filter favorites | Filter wishlist by category | Member has favorites in multiple categories | Filter chip values | Open Favorites; select filters; clear filter | List matches filter; no-results state and clear action work | UI, Functional | Medium | Minor | Yes |  |
| CIRC-040 | Mobile Wishlist | Remove favorite from wishlist | Remove via card toggle | Favorite exists | Book ID | Tap remove on favorite card | Book removed from list; backend interaction removed; empty state if last item | Mobile E2E | High | Major | Yes |  |

### Users, Profiles, Admin Member Management, and Fines

| Test Case ID | Module/Feature | Test Scenario | Test Case Title | Preconditions | Test Data | Test Steps | Expected Result | Test Type | Priority | Severity | Automation Candidate | Remarks or Assumptions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| USER-001 | Users API | Admin list users | List users with search/pagination | Admin token; >10 users | page/limit/search | GET `/users?page=1&limit=10&search=...` | 200 with data and totalCount; search matches name/email/member_id | API, Functional | High | Major | Yes |  |
| USER-002 | Users API | Create user | Admin creates member | Admin token | Name, mixed-case email, phone, address | POST `/users` | 201; email lowercased; member_id generated; joined_date today | API, CRUD, DB | High | Major | Yes |  |
| USER-003 | Users API | Duplicate email | Reject duplicate email case-insensitively | Existing user | Same email different case | POST `/users` | 409; no duplicate row | Validation, DB | High | Major | Yes |  |
| USER-004 | Users API | Create invalid user | Missing/invalid name/email | Admin token | Blank name, malformed email, long strings | POST `/users` | 422 or controlled error; no row | Validation, Negative | High | Major | Yes | Schema lacks email validation for admin create; gap. |
| USER-005 | Users API | Member profile update | Member updates own profile | User token | Name/email/phone/address | PUT `/users/{own_id}` | 200; fields updated; updated_at changes if implemented | API, Functional | High | Major | Yes | Backend does not set updated_at on update; gap. |
| USER-006 | Users API | Null fields ignored | Update with null values | Existing user | `{phone:null,address:null}` | PUT `/users/{id}` | Existing non-null values remain unchanged | API, Edge | Medium | Minor | Yes | Code ignores null values. |
| USER-007 | Users API | Delete user no activity | Admin deletes inactive user | User has no loans/reservations/fines | user_id | DELETE `/users/{id}` | 200 success; user no longer retrievable | API, CRUD, DB | Medium | Major | Yes | README says soft delete, code hard deletes. |
| USER-008 | Users API | Delete user with activity | Prevent deleting historical user | User has loan/reservation/fine | user_id | DELETE `/users/{id}` | 409; user remains | Data Integrity | High | Critical | Yes |  |
| USER-009 | Users API | Profile image upload | Upload own profile image | Member token; own user | Valid image | PUT `/users/{id}/profile-image`; GET image | Image stored and served; user profile_image path updated | API, File Upload | Medium | Major | Yes | Admin also allowed. |
| USER-010 | Users API | Profile image authorization | Upload/delete another user's image | User A token; User B ID | Valid image | PUT/DELETE `/users/{userB}/profile-image` | 403; image unchanged | Security, RBAC | Critical | Critical | Yes |  |
| USER-011 | Users API | Profile stats | Fetch member stats | User has loans/fines/reservations | user_id | GET `/users/{id}/stats` | Counts and total unpaid fines match DB | API, DB Validation | High | Major | Yes | Active counts currently count all loans/reservations; verify requirement. |
| USER-012 | Admin Users UI | List/search/paginate members | Admin manages members | Admin logged in; >10 users | Search term | Open Users; search; paginate | Results, total count, loading and empty states correct | UI, Functional | High | Major | Yes | Status filter currently passed but backend ignores; gap. |
| USER-013 | Admin Users UI | Create member modal | Create user from admin UI | Admin logged in | Valid name/email/phone/address | Click Create New User; submit | Modal closes; new user appears; generated member ID displayed | UI, E2E | High | Major | Yes |  |
| USER-014 | Admin Users UI | Edit member | Update member contact details | Existing user | Changed phone/address/name | Click edit; change values; submit | Row updates; no duplicate user created | UI, Functional | High | Major | Yes |  |
| USER-015 | Admin Users UI | Delete/deactivate copy | Delete user confirmation language | User with and without activity | N/A | Click delete; observe confirm text; confirm | No-activity user deleted; activity user shows error | UI, Data Integrity | Medium | Major | Yes | UI says deactivate, API deletes. |
| USER-016 | Mobile Profile | Load profile | Member profile screen loads | Member logged in; profile/stats available | N/A | Open Profile | Header, stats, account/preferences/support/sign out render | UI, Functional | High | Major | Yes |  |
| USER-017 | Mobile Profile | Edit profile validation | Reject invalid edit form | Profile screen | Blank name, invalid email | Open Edit; clear name or use invalid email; save | Validation message; no API update | Validation, UI | High | Major | Yes |  |
| USER-018 | Mobile Profile | Save profile | Update profile from mobile | Member logged in | New name/email/phone/address | Edit Profile; save | Success snackbar; Profile refreshes with new data; current user provider updated | Mobile E2E | High | Major | Yes |  |
| USER-019 | Mobile Profile | Missing member identity | Save profile when user ID cannot resolve | Auth/current providers empty | Valid fields | Tap Save | Error snackbar asks user to login again; no API call | Error Handling | Medium | Major | Yes |  |
| USER-020 | Mobile Profile | Theme toggle persistence | Toggle dark mode | Profile screen | Toggle value | Toggle dark mode; navigate away/back; restart app if persisted | Theme changes consistently; no unreadable text | UI, Compatibility | Low | Minor | Yes | Persistence behavior not confirmed. |
| FINE-001 | Fines API | List fines | Admin lists fines with search/status/page | Admin token; fines exist | search/status/page/limit | GET `/fines` | 200 with data, totalCount, pagination; joined user/book/payment fields valid | API, Functional | High | Major | Yes |  |
| FINE-002 | Fines API | Create manual fine | Admin creates fine | Member exists | member_id, optional loan_id, amount, date, reason | POST `/fines` | 201; status unpaid; reason defaults if blank; summary reflects due | API, CRUD, DB | High | Major | Yes |  |
| FINE-003 | Fines API | Fine amount validation | Reject zero/negative fine | Admin token | amount 0, -1 | POST `/fines` | 422; no fine row | Boundary, Validation | High | Major | Yes |  |
| FINE-004 | Fines API | Loan/member mismatch | Fine loan for wrong member | Loan belongs to A; fine for B | member_id B, loan_id A | POST `/fines` | 400 loan does not belong to member | Data Integrity | High | Critical | Yes |  |
| FINE-005 | Fines API | Member fine summary | Member views own fine summary | Member has unpaid/paid fines | own member_id | GET `/fines/member/{id}/summary` | total_due sums unpaid only; unpaid_count correct | API, DB Validation | High | Major | Yes |  |
| FINE-006 | Fines API | Fine payment partial | Record partial physical payment | Unpaid fine amount 100 | payment_amount 30 | PUT `/fines/{id}` | Payment row created; fine_amount 70; status unpaid; total_paid 30 | API, Financial, DB | Critical | Critical | Yes |  |
| FINE-007 | Fines API | Fine payment full | Record full payment | Unpaid fine amount 100 | payment_amount 100 | PUT fine | Fine amount 0; status paid; paid_at set; payment recorded | API, Financial | Critical | Critical | Yes |  |
| FINE-008 | Fines API | Overpayment rejected | Pay more than due | Unpaid fine amount 100 | payment_amount 100.01 | PUT fine | 400 payment exceeds due; no payment row; amount unchanged | Boundary, Financial | Critical | Critical | Yes |  |
| FINE-009 | Fines API | Closed fine payment rejected | Pay paid/waived fine | Fine status paid or waived | payment_amount 1 | PUT fine | 409 already closed; no payment row | Negative, Financial | Critical | Critical | Yes |  |
| FINE-010 | Fines API | Update status | Mark fine paid/waived/unpaid | Existing fine | statuses valid and invalid | PUT fine with status | Valid statuses accepted; invalid returns 400 | Validation, API | High | Major | Yes | Mark paid zeros amount without payment row. |
| FINE-011 | Fines API | Delete fine cascade | Delete fine with payments | Fine has payment rows | fine_id | DELETE `/fines/{id}` | Fine and payments deleted; response success | API, DB Integrity | Medium | Major | Yes |  |
| FINE-012 | Admin Fines UI | Tabs and search | Filter fines all/unpaid/paid | Admin logged in; mixed fines | search terms | Open Fines; change tabs/search | Rows match search/status; loading/error/empty states correct | UI, Functional | High | Major | Yes |  |
| FINE-013 | Admin Fines UI | Create fine modal | Create manual fine in UI | Admin logged in; users loaded | Member, amount, dates, reason | Click Create Fine; submit | Fine appears; errors shown for invalid or missing user | UI, E2E | High | Major | Yes |  |
| FINE-014 | Admin Fines UI | Manage payment | Record partial/full payment in UI | Unpaid fine | Amount, notes | Open manage modal; enter amount; record | Partial keeps modal open with remaining due; full closes modal; list refreshes | UI, Financial | Critical | Critical | Yes |  |
| FINE-015 | Admin Fines UI | Payment input validation | Reject invalid payment amount | Manage modal open | Blank, text, zero, negative, overpay | Click record | Client rejects non-positive; API rejects overpay; no duplicate submission | Validation, Negative | High | Major | Yes |  |
| FINE-016 | Admin Fines UI | Renew from fine | Renew related loan from fine modal | Fine has active loan_id | selected fine | Click renew loan | Loan due date extends; UI loading state clears; errors handled | Integration | Medium | Major | Yes | Behavior visible in page code. |

### Notifications, Content, Settings, Admin Dashboard, and Sync

| Test Case ID | Module/Feature | Test Scenario | Test Case Title | Preconditions | Test Data | Test Steps | Expected Result | Test Type | Priority | Severity | Automation Candidate | Remarks or Assumptions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| NOTIF-001 | Notifications API | List recipient notifications | Member/admin lists notifications | Notifications exist for user and admin | Token | GET `/notifications?limit=50` | Member sees own user notifications; admin sees admin notifications only | API, RBAC | High | Major | Yes |  |
| NOTIF-002 | Notifications API | Limit validation | Boundary for notification limit | Valid token | limit 1,100,0,101 | GET `/notifications?limit=...` | 1/100 accepted; 0/101 rejected with 422 | Boundary, API | Medium | Minor | Yes |  |
| NOTIF-003 | Notifications API | Unread count | Get unread count | Notifications mixed read/unread | Token | GET `/notifications/unread-count` | Count equals unread rows for recipient | API, DB | Medium | Minor | Yes |  |
| NOTIF-004 | Notifications API | Mark single read | Mark own notification read | Unread notification | notification_id | POST `/notifications/{id}/read` | Notification read=true; read_at set; unread count decrements | API, Functional | High | Major | Yes |  |
| NOTIF-005 | Notifications API | Mark other notification read | IDOR notification read | User A token; User B notification | notification_id | POST read | 404 or denied; notification remains unread | Security, RBAC | Critical | Critical | Yes | Service returns not found. |
| NOTIF-006 | Notifications API | Read all | Mark all notifications read | Multiple unread | Token | POST `/notifications/read-all` | Success; marked count equals previously unread; all read | API, Functional | Medium | Minor | Yes |  |
| NOTIF-007 | Device Tokens | Register/delete device token | Mobile push token lifecycle | Member token | token/platform | POST then DELETE `/notifications/device-token` | Token upserted without duplicates; delete returns marked 1 then 0 on repeat | API, Mobile Integration | Medium | Minor | Yes |  |
| NOTIF-008 | Mobile Notifications | Notification list UI | View and read notifications | Member logged in; notifications exist | N/A | Open notifications; tap unread card; tap Read all | Cards display category/time local; unread dot removed; Read all disabled when count 0 | Mobile UI, E2E | Medium | Minor | Yes | Timezone-sensitive display. |
| CONTENT-001 | Blogs API | Public published blogs | Member lists blogs | Published and unpublished blogs exist | content_read token | GET `/blogs` | Published blogs only, newest first | API, Functional | Medium | Minor | Yes |  |
| CONTENT-002 | Blogs API | Include unpublished admin only | Admin vs member includes unpublished | Admin and member tokens | `include_unpublished=true` | GET `/blogs?include_unpublished=true` | Admin sees all; member receives 403 | API, RBAC | High | Major | Yes |  |
| CONTENT-003 | Blogs API | Blog CRUD validation | Admin creates/updates/deletes blog | Admin token | Boundary title/excerpt/content/read_minutes | POST/PUT/DELETE `/blogs` | Valid data persists; invalid lengths/read_minutes rejected; deleted blog 404 | API, CRUD, Validation | Medium | Major | Yes |  |
| CONTENT-004 | Videos API | Video CRUD validation | Admin manages videos | Admin token | YouTube IDs valid/invalid, title/description | POST/PUT/DELETE `/videos` | Valid IDs accepted; IDs with spaces/symbols rejected; deleted video 404 | API, CRUD, Validation | Medium | Major | Yes | YouTube ID 6-32 chars, `[A-Za-z0-9_-]`. |
| CONTENT-005 | Mobile Blogs | Blog list/detail | View blogs on mobile | Published blog exists | N/A | Open Blogs; tap article | List renders; detail shows title/content; errors/empty states handled | Mobile UI | Low | Minor | Yes | Based on Flutter blog views. |
| CONTENT-006 | Mobile Videos | Video list | View videos on mobile | Published video exists | N/A | Open Videos | Videos show thumbnail/title/speaker/duration; invalid thumbnail fallback works | Mobile UI | Low | Minor | Yes |  |
| SET-001 | Settings API | Get/create settings | First settings fetch creates defaults | No settings row | Read token | GET `/settings`; query DB | 200 defaults; one settings row created only | API, DB | High | Major | Yes |  |
| SET-002 | Settings API | Update valid settings | Admin updates loan/fine settings | Admin token | loan 21, max books 7, grace 0, fine rate 1.25, cap 100 | PUT/PATCH `/settings` | Values persist; subsequent borrow uses loan period/max/fine threshold | API, Integration | Critical | Critical | Yes |  |
| SET-003 | Settings API | Boundary settings | Validate min/max settings | Admin token | loan 1; max_books 1; grace 0; interval 1/365; negative values | PUT/PATCH | Valid boundaries accepted; invalid values rejected 422 | Boundary, Validation | High | Major | Yes |  |
| SET-004 | Settings API | Spreadsheet ID normalization | Normalize Google Sheet URL/ID | Admin token | Full spreadsheet URL, blank, >256 chars | PUT settings | URL normalized to ID; blank becomes null; overlength rejected | API, Validation | Medium | Minor | Yes |  |
| SET-005 | Admin Settings UI | Save fine settings | Admin edits rules | Admin logged in | Valid changed settings | Open Settings > Fine Rules; edit; save | Success alert; settings persisted and reload correctly | UI, Integration | High | Major | Yes |  |
| SET-006 | Admin Settings UI | Conditional notification field | Toggle send notifications | Admin logged in | Checkbox on/off | Toggle send_notifications | Days-before field hides when off and value persists/updates correctly | UI, Functional | Medium | Minor | Yes |  |
| SET-007 | Admin Settings UI | Invalid settings save | Save invalid numeric values | Admin logged in | 0 loan period, negative cap, interval 366 | Enter values; save | API error alert; previous persisted values remain | Validation, Negative | High | Major | Yes | HTML min not sufficient. |
| SET-008 | Admin Settings UI | Library/profile tabs | Non-persisted info fields | Admin logged in | Library name/address/profile fields | Edit Library Info/Admin Profile; save | Clarify whether fields persist; currently likely not sent to API | UI, Requirement Gap | Medium | Minor | No | Marked as ambiguity. |
| SYNC-001 | Content Sync | Manual sync success | Run Google Sheet sync | Admin token; sheet shared; tabs configured | Valid spreadsheet ID/tabs | POST `/content-sync/run` or Run Manual Sync | Settings saved first; sync returns success counts; last sync status/time updated | Integration, E2E | High | Major | Yes | Network to Google needed; mock for CI. |
| SYNC-002 | Content Sync | Missing/unreadable sheet | Manual sync failure | Admin token; invalid sheet ID | Invalid ID | Run sync | 400 error; settings last sync status failed and message stored; UI alert shown | Error Handling, Integration | High | Major | Yes |  |
| SYNC-003 | Content Sync | Malformed sheet rows | Partial/bad data import | Sheet has invalid rows/duplicates | Rows with missing title, bad video ID, bad image URL | Run sync | Valid rows imported per service rules; invalid rows reported or skipped without corrupting existing data | Data Integrity | High | Major | Yes | Need exact sync service expectations. |
| DASH-001 | Dashboard API/UI | Dashboard metrics | Admin views dashboard | Admin logged in; seeded books/users/loans/fines | N/A | GET `/dashboard`; open dashboard page | Stats match DB; recent loans/top books/recent fines render | Functional, DB | High | Major | Yes |  |
| DASH-002 | Dashboard API/UI | Empty dashboard | No operational data | Empty DB except settings | N/A | Open dashboard | Shows zero/empty states without crashes | Edge, UI | Medium | Minor | Yes |  |
| DASH-003 | Admin Notifications UI | Admin notification menu/page | Admin views notification menu and page | Admin logged in; admin notifications exist | N/A | Open header notification menu; notifications page; mark read | Unread count/list update; read state persists | UI, Functional | Medium | Minor | Yes |  |
| LOANH-001 | Admin Returns UI | Return from returns page | Admin processes return | Active loans exist | loan_id, returned_by | Open Returns; return loan | Loan marked returned; copies increment; row leaves active returns | UI, E2E | High | Major | Yes | Based on admin returns route/page. |
| LOANH-002 | Admin Loan History UI | View loan history | Admin reviews history | Mixed loans | Status filter | Open Loan History; filter statuses | Rows sorted by loan/return date and include book/member data | UI, Functional | Medium | Minor | Yes |  |

### API Contract, Security, Performance, Compatibility, Accessibility, and Resilience

| Test Case ID | Module/Feature | Test Scenario | Test Case Title | Preconditions | Test Data | Test Steps | Expected Result | Test Type | Priority | Severity | Automation Candidate | Remarks or Assumptions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| API-001 | API Contract | HTTP methods | Unsupported method handling | API running | OPTIONS/HEAD/POST to GET-only routes | Send unsupported methods | 405/appropriate response; CORS preflight allowed for configured methods | API, Compatibility | Medium | Minor | Yes |  |
| API-002 | API Contract | Malformed JSON | Send invalid JSON to JSON endpoints | Auth token | Truncated JSON | POST/PUT routes | 422/400 validation error; no mutation | API, Negative | High | Major | Yes |  |
| API-003 | API Contract | Content-Type mismatch | Wrong content-type on JSON endpoints | Auth token | text/plain body | POST/PUT routes | Controlled validation error; no server crash | API, Negative | Medium | Major | Yes |  |
| API-004 | API Contract | Response schema | Validate OpenAPI schemas | API running | Representative route responses | Call all endpoints with valid data; validate fields/types | Responses conform to documented schemas and status codes | API, Contract | Critical | Major | Yes | Use OpenAPI schema validator. |
| API-005 | Request Size | Body too large | Enforce max request size | API running | Body > `MAX_REQUEST_SIZE_BYTES` | POST large JSON/image | 413 `Request body too large`; connection remains healthy | Security, Performance | High | Major | Yes | Default 10 MB. |
| API-006 | Security Headers | Required response headers | Verify security headers | API running | Any route; production env for HSTS | GET `/`, `/auth/debug/identity` | nosniff, DENY, no-referrer, permissions policy present; auth routes no-store; HSTS in prod | Security | High | Major | Yes |  |
| API-007 | CORS | Allowed origins only | Validate CORS policy | API running with origins configured | Allowed and disallowed Origin headers | Send preflight/GET | Allowed origin gets CORS headers; disallowed does not | Security, Compatibility | High | Major | Yes | `*` invalid with credentials. |
| API-008 | Health | Health and DB checks | Verify root and DB endpoints | API/DB running | N/A | GET `/`; GET `/test-db` | Root JSON returned; DB returns result 1; DB outage handled clearly | Smoke, API | Critical | Blocker | Yes |  |
| SEC-001 | Injection | Search/filter injection | Attempt SQL/script injection in query params | Auth token | `' OR 1=1 --`, `<script>`, `%`, Unicode | Use search params in users/fines/books admin gateway | No SQL error; output escaped in UI; results limited to legitimate matches | Security, Negative | Critical | Critical | Yes |  |
| SEC-002 | Stored XSS | User/book/content stored HTML | Admin creates data with script/HTML | Admin token | `<img onerror=alert(1)>`, `<script>` in title/name/content | Create and view in admin/mobile | Text is escaped; script does not execute; API stores/sanitizes per requirement | Security | Critical | Critical | Yes | Sanitization requirement unclear. |
| SEC-003 | Sensitive Data | No secrets exposed | Error/log/API responses | Misconfigured env; failed auth | Trigger errors | Inspect responses and logs | No tokens, client secrets, DB URL, stack traces in user-facing responses | Security | Critical | Critical | Yes |  |
| SEC-004 | Privilege Escalation | Scope/admin combination | User with manage scope but no admin role calls admin-only route | Token has `books_manage`, no admin group | POST `/books` | 403 Administrator privileges required | Security, RBAC | Critical | Critical | Yes | Admin routes require both. |
| SEC-005 | ID Enumeration | Nonexistent vs unauthorized | Access guessed IDs | Member token | Existing other ID, nonexistent ID | GET user/fine/reservation by ID | Unauthorized existing resource not exposed; error messages do not leak sensitive details beyond acceptable | Security | High | Major | Yes | Current order may reveal some IDs; review. |
| SEC-006 | Rate Limits | Default API rate limit | Exceed default route limit | Rate limit enabled | >60 requests/min default | Repeated GET protected route | 429 after threshold; app recovers after window | Security, Performance | Medium | Major | Yes | Configurable. |
| PERF-001 | Books List Performance | Large catalog load | Admin and mobile list with large dataset | 10k books/categories | Search/filter/list requests | Measure response and UI render | API/admin gateway responds within SLA; UI remains responsive; no memory blow-up | Performance | High | Major | Yes | SLA not specified; propose p95 <2s for API. |
| PERF-002 | Search Performance | Mobile search on large catalog | Mobile has large book list | 10k books | Type rapidly in search field | Filtering debounces or remains smooth; no dropped frames/freezes | Performance, UX | Medium | Major | Yes | Implementation may filter client-side. |
| PERF-003 | Concurrent Circulation | Parallel borrow/return/renew | Multiple users active | 50 concurrent ops | Run concurrent requests | No duplicate IDs, negative copies, double returns, or DB deadlocks | Performance, Concurrency, DB | Critical | Critical | Yes | Random ID collisions also tested. |
| PERF-004 | Image Performance | Large valid images | Admin uploads near-limit images | 5-10 MB image | Upload and render list/detail | Upload respects limit; thumbnails render without excessive load time | Performance, File Upload | Medium | Major | Yes |  |
| RES-001 | Network Offline | Mobile offline startup | Device offline after login | Cached/no cached data variants | Launch app offline | Shows meaningful error/offline state; retry works when online; no crash | Resilience, Mobile | High | Major | Yes | Offline caching requirements unclear. |
| RES-002 | Timeout Recovery | API timeout during submit | Slow backend | Borrow/fine/user submit | Start submit; backend times out | Loading state clears; user sees error; retry does not duplicate successful server-side operation | Resilience, Duplicate | Critical | Critical | Yes | Especially payments/borrow. |
| RES-003 | Browser Refresh | Admin refresh/back nav | Admin form/list pages | Admin logged in | Open modals/filters/pages | Refresh and browser back/forward | Protected page reloads with session; filters may reset predictably; no unauthorized flash | UI, Session | Medium | Minor | Yes |  |
| RES-004 | Repeated Clicks | Duplicate submissions | Fast double-click actions | Any create/payment/borrow/delete | Rapid clicks | Only one mutation occurs; buttons disabled or API idempotency prevents duplicates | Concurrency, UI | Critical | Critical | Yes | Critical for payments/loans. |
| A11Y-001 | Admin Accessibility | Keyboard navigation | Admin portal accessible by keyboard | Admin logged in | All pages | Tab through nav, buttons, modals, forms; use Enter/Escape | Focus order logical; visible focus; modal traps focus; buttons have accessible names | Accessibility | High | Major | Yes | Use axe + manual keyboard. |
| A11Y-002 | Mobile Accessibility | Screen reader labels | Mobile core flows with TalkBack/VoiceOver | Device/emulator | Login, search, book detail, borrow, profile | Navigate with screen reader | Controls announced clearly; icons have labels/tooltips; dynamic errors announced | Accessibility | High | Major | No | Manual recommended. |
| A11Y-003 | Color Contrast | Contrast and text scaling | Admin/mobile at large text and dark mode | Text scale 200%; dark mode mobile | Inspect pages | Text remains readable; no clipping/overlap; contrast meets WCAG AA | Accessibility, Responsive | High | Major | Yes | Visual automation plus manual. |
| RESP-001 | Admin Responsive | Admin pages at breakpoints | Browser widths 320, 375, 768, 1024, 1440 | Admin logged in | Books/users/fines/settings | Resize/visit pages | Mobile cards and desktop tables render without horizontal body overflow except intended table scroll | Responsive, UI | High | Major | Yes |  |
| RESP-002 | Mobile Device Matrix | Cross-device mobile | Android/iOS phone/tablet | Common device sizes | Run major flows | Layout usable; keyboard does not cover critical controls; bottom sheets fit 88% height | Compatibility, Responsive | High | Major | Yes |  |
| COMP-001 | Cross Browser Admin | Browser compatibility | Chrome, Firefox, Safari, Edge | Admin env | Smoke admin flows | Auth redirect, forms, tables, uploads, downloads/sync work consistently | Compatibility | High | Major | Yes | Safari cookie behavior important. |
| COMP-002 | Mobile Platform | Platform compatibility | Android emulator, physical Android, iOS simulator/device | Configured app | Auth, borrow, wishlist, notifications | Flows work with correct redirect URL and SERVER_URL; no platform-specific crashes | Compatibility, E2E | Critical | Critical | Yes | iOS callback URI must be configured. |
| L10N-001 | Timezone Dates | Date handling in Asia/Colombo vs UTC | Server timezone, client timezone varied | Loan/fine/reservation dates around midnight | Borrow/return/reserve/read notification | Dates stored as expected; displayed local times correct; no off-by-one day | Localization, Timezone | High | Major | Yes | Current user timezone Asia/Colombo. |
| L10N-002 | Unicode Inputs | Unicode/special characters | Forms/API | Names/titles in Sinhala/Tamil, emoji, apostrophes | Create/update users/books/categories/blogs | Unicode stored/displayed correctly; search finds text; no encoding errors | Validation, Localization | Medium | Major | Yes | Emoji acceptance should be confirmed. |
| DB-001 | Transaction Integrity | Failed borrow rollback | Force DB integrity error during loan create | Existing duplicate loan ID or DB constraint fail | Mock random duplicate | POST borrow | Transaction rolls back; copies restored; 409 returned | DB, Error Recovery | Critical | Critical | Yes | Code handles IntegrityError after decrement. |
| DB-002 | Referential Integrity | Delete records with dependencies | Books/categories/users/fines with related rows | Seed relationships | Attempt deletes | Deletions are blocked or cascaded according to requirement; no orphan rows | DB Integrity | Critical | Critical | Yes | Several policies unspecified. |
| DB-003 | Seed/Migration | Fresh environment validation | Empty DB then seed/migrate | New DB | Seed script | Run migration/seed; smoke API | Required categories/books/settings/users exist; seed idempotent or documented | Environment, DB | High | Major | Yes |  |

## A. Requirement Gaps and Ambiguities

| Area | Gap or Ambiguity | Impact |
|---|---|---|
| User delete | Admin README says users are soft deleted/deactivated; backend performs hard delete when no activity. | Tests and UX copy may conflict with actual behavior. |
| Admin user status | Users UI has Active/Suspended/Inactive filter, but backend user schema/service has no status handling. | Filter may be misleading or nonfunctional. |
| Category deletion | Expected behavior when deleting categories used by books is not specified. | Risk of FK errors or orphan/unknown category behavior. |
| Book deletion | Expected behavior when deleting books with active loans/reservations/favorites/fines is not specified. | High data-integrity risk. |
| Reservations | API allows reservation regardless of copy availability and blocks if any loan exists, not only active loan. | Product rule should clarify when reservations are allowed. |
| Fines | No explicit automatic overdue fine generation rule found, despite settings for grace period, daily fine rate, max cap. | Manual fine tests are clear; overdue automation is unclear. |
| Profile stats | Active loans/reservations counts appear to count all rows, not only active rows. | Metrics may be inaccurate if requirement expects active only. |
| Library Info/Admin Profile settings | Admin Settings UI fields appear not wired to backend settings schema. | Save behavior is ambiguous. |
| Content sync | Exact handling for malformed rows, duplicates, partial failures, and delete/overwrite strategy is not documented. | Sync data integrity needs product decision. |
| Offline behavior | No explicit caching/offline requirements found for mobile app. | Offline tests should verify graceful errors unless caching is required. |
| SLA/performance | No response-time, throughput, or dataset-size requirements documented. | Performance tests use proposed QA targets. |
| Localization | Currency shown as LKR and dates are local, but supported locales/languages are not specified. | Localization coverage remains assumption-based. |
| Notification delivery | Push provider behavior and failure retry policy are not fully specified. | API notification persistence can be tested; push delivery needs infra spec. |
| Image handling | Exact allowed image MIME types and max dimensions are not documented in requirements. | Tests infer behavior from image validation and max body middleware. |
| Admin auth roles | Admin group names are env-driven; exact production roles/groups not specified. | RBAC tests need test tenant mapping. |

## B. QA Clarification Questions

1. Should admin user deletion be soft delete/deactivation, or is hard delete acceptable when the user has no history?
2. What should happen when deleting books/categories that are referenced by loans, reservations, favorites, or content?
3. Are reservations allowed only when no copies are available, or can members reserve any book?
4. Should members be blocked from reserving a book if they had a returned historical loan, or only if they currently have an active loan?
5. Are overdue fines generated automatically? If yes, what scheduled job, formula, cap, grace period, and rounding rules apply?
6. Should profile stats count only active loans/reservations, or lifetime totals?
7. Should admin Settings Library Info and Admin Profile fields persist? If yes, which API fields store them?
8. What are the supported browsers, OS versions, Android/iOS minimum versions, and device breakpoints?
9. What are the official performance SLAs for API p95 latency, admin page load, mobile startup, sync duration, and concurrent users?
10. What is the exact Google Sheet schema for Books, Blogs, and Videos, including required columns and duplicate matching keys?
11. Should search support only client-side substring matching, or server-side pagination/search for large catalogs?
12. What image formats, max dimensions, and max file sizes are officially supported for book covers and profile images?
13. What are the accepted currencies and timezone for fines, due dates, and notification scheduling?
14. What user-facing behavior is expected when tokens expire on mobile?
15. Should content fields allow HTML/Markdown or plain text only?

## C. Assumptions Made

| ID | Assumption |
|---|---|
| ASM-001 | Admin users have both a configured admin group/role and the required API scopes. |
| ASM-002 | Members may access only their own member-scoped users, favorites, loans, reservations, fines, notifications, and profile images unless admin. |
| ASM-003 | Currency values are LKR because admin settings label fine rates as LKR. |
| ASM-004 | Dates should be validated and displayed without off-by-one errors in the user's local timezone. |
| ASM-005 | Mobile offline behavior is graceful degradation, not full offline mode, unless later requirements state caching. |
| ASM-006 | Security tests expect text output to be escaped in React/Flutter and no executable HTML/script in user-controlled fields. |
| ASM-007 | Performance targets should be agreed later; this suite flags performance risks without asserting undocumented SLA values. |
| ASM-008 | Google Sheet sync should not corrupt existing valid data when individual rows are malformed. |
| ASM-009 | Admin gateway APIs are part of the test surface because the admin UI depends on them for filtering, normalization, and auth. |

## D. High-Risk Areas

| Risk Area | Why It Is High Risk | Representative Tests |
|---|---|---|
| Borrow/return concurrency | Copies can go negative or duplicate loans can be created under parallel requests. | CIRC-009, PERF-003, DB-001 |
| Fines and payments | Financial data requires exact validation, rollback, and duplicate-submit protection. | FINE-006 to FINE-015, RES-002, RES-004 |
| RBAC/IDOR | Many member-specific endpoints depend on subject-or-admin checks. | AUTH-020, AUTH-021, SEC-004, SEC-005 |
| Admin session cookies | Tampering or stale cookies could expose admin data. | AUTH-017 to AUTH-019 |
| Book/category deletion | Referential behavior is unclear and can damage historical circulation data. | CAT-018, DB-002 |
| Sync imports | External data can be malformed, duplicated, slow, or unavailable. | SYNC-001 to SYNC-003 |
| Image upload/static assets | File uploads and asset serving are common security and performance targets. | CAT-011, CAT-012, CAT-036, PERF-004 |
| Timezone/date logic | Loan due dates, return dates, fines, and notifications are date-sensitive. | L10N-001, CIRC-001, CIRC-011 |
| Admin/mobile divergence | Admin gateway normalizes/paginates differently from backend. | CAT-019 to CAT-026, API-004 |

## E. Recommended Smoke-Test Suite

| Smoke ID | Covered Test Cases | Purpose |
|---|---|---|
| SMK-001 | API-008 | Backend and DB health. |
| SMK-002 | AUTH-001, AUTH-015 | Member and admin can authenticate. |
| SMK-003 | CAT-001, CAT-019, CAT-027 | Catalog loads in API, admin, and mobile. |
| SMK-004 | CIRC-001, CIRC-011 | Borrow and return one book. |
| SMK-005 | CIRC-020, CIRC-024 | Reserve and cancel one book. |
| SMK-006 | FINE-002, FINE-007, FINE-014 | Create and fully pay a fine. |
| SMK-007 | USER-002, USER-018 | Create/edit member data. |
| SMK-008 | NOTIF-001, NOTIF-004, NOTIF-008 | Notification list and read flow. |
| SMK-009 | SET-001, SET-005 | Settings load and save. |
| SMK-010 | AUTH-017, AUTH-018 | Protected admin route/API reject unauthenticated access. |

## F. Recommended Regression-Test Suite

| Regression Area | Included Test Cases |
|---|---|
| Auth/session/RBAC | AUTH-001 to AUTH-024, SEC-004, SEC-005 |
| Catalog/admin books/mobile search | CAT-001 to CAT-036 |
| Circulation/reservations/favorites | CIRC-001 to CIRC-040 |
| Users/profile/fines | USER-001 to USER-020, FINE-001 to FINE-016 |
| Notifications/content/settings/sync/dashboard | NOTIF-001 to NOTIF-008, CONTENT-001 to CONTENT-006, SET-001 to SET-008, SYNC-001 to SYNC-003, DASH-001 to DASH-003 |
| Cross-cutting hardening | API-001 to API-008, SEC-001 to SEC-006, PERF-001 to PERF-004, RES-001 to RES-004, A11Y-001 to A11Y-003, RESP-001 to RESP-002, COMP-001 to COMP-002, L10N-001 to L10N-002, DB-001 to DB-003 |

## G. Recommended Automation Candidates

| Layer | Recommended Tools | High-Value Cases |
|---|---|---|
| Backend API | pytest + httpx/TestClient + DB fixtures + OpenAPI schema validation | AUTH-010 to AUTH-014, CAT-001 to CAT-018, CIRC-001 to CIRC-025, FINE-001 to FINE-011, NOTIF-001 to NOTIF-007, SET-001 to SET-004, API/SEC/DB cases |
| Admin E2E | Playwright | AUTH-015 to AUTH-019, CAT-019 to CAT-026, USER-012 to USER-015, FINE-012 to FINE-016, SET-005 to SET-008, SYNC-001/SYNC-002 with mocked backend |
| Mobile Widget/Integration | Flutter test + integration_test + mocked repositories | AUTH-001 to AUTH-009, CAT-027 to CAT-035, CIRC-026 to CIRC-033, USER-016 to USER-020, NOTIF-008 |
| Accessibility | axe-core for admin, Playwright accessibility snapshots, manual TalkBack/VoiceOver | A11Y-001 to A11Y-003 |
| Performance/Concurrency | Locust/k6, pytest-xdist/concurrent futures, DB isolation checks | CIRC-009, PERF-001 to PERF-004, RES-004 |
| Security | OWASP ZAP baseline, custom pytest security tests | SEC-001 to SEC-006, CAT-036, API-005 to API-007 |

## H. Test Data Requirements

| Data Set | Required Records |
|---|---|
| Members | Admin user; regular member with complete profile; member missing phone; member missing address; member missing both; member with unpaid fines; member at max loan limit; member with no activity; member with historical activity. |
| Books | Available book with copies >1; last-copy book with copies=1; unavailable book with copies=0; book with long metadata; book with image; book without image; books across categories/authors/languages/years/ratings. |
| Categories | Unique categories; duplicate-name category candidate; category referenced by books; category with valid/invalid image URLs. |
| Loans | Active loans, returned loans, overdue loans, due-soon loans, loans with missing book/user edge data if possible. |
| Reservations | Pending/active, cancelled, fulfilled/completed/expired statuses for duplicate-rule testing. |
| Fines | Unpaid fine, paid fine, waived fine, fine with partial payments, fine linked to loan, fine without loan, fine for threshold boundary. |
| Notifications | User unread/read notifications, admin unread/read notifications, multiple categories, old/new timestamps. |
| Content | Published/unpublished blogs/videos, invalid YouTube IDs, long content, missing optional fields. |
| Sync Sheets | Valid Books/Blogs/Videos tabs, missing tabs, duplicate keys, malformed rows, invalid image/video values. |
| Security Inputs | SQL-like strings, HTML/script payloads, Unicode names/titles, very long strings, path traversal paths, malformed JSON. |

## I. Dependencies and Environment Requirements

| Dependency | Requirement |
|---|---|
| Backend | Python 3.11+, PostgreSQL test database, FastAPI app env configured, seeded/migrated test DB, Asgardeo base URL or mocked IdP. |
| Admin | Node.js 20+, npm dependencies, Next.js env vars, admin OAuth callback configured, browser automation test user. |
| Mobile | Flutter SDK, Android/iOS emulator or devices, `SERVER_URL`, `ASGARDEO_CLIENT_ID`, `ASGARDEO_BASE_URL`, redirect URI configuration. |
| Identity | Asgardeo test tenant with member/admin users, required scopes, admin groups, token introspection/client credentials where needed. |
| External Sync | Shared/published Google Sheet test file or mocked CSV export endpoints. |
| Push Notifications | Test FCM/APNs configuration or mocked notification provider for API-level tests. |
| Test Isolation | Resettable DB fixtures, deterministic dates/timezone, mocked random IDs where concurrency/duplicate tests need determinism. |
| Browsers/Devices | Chrome, Firefox, Safari/WebKit, Edge; Android and iOS mobile targets; responsive browser widths 320, 375, 768, 1024, 1440. |
| Security/Performance | OWASP ZAP/axe/k6 or equivalent, safe non-production environment, monitoring/log access. |

## J. Traceability Between Requirements and Test Cases

| Requirement/Workflow | Test Case IDs |
|---|---|
| Member authentication and signup | AUTH-001 to AUTH-014 |
| Admin authentication/session protection | AUTH-015 to AUTH-024 |
| Books CRUD, validation, search, images | CAT-001 to CAT-013, CAT-019 to CAT-026 |
| Categories CRUD | CAT-014 to CAT-018, CAT-026 |
| Mobile home/search/book details | CAT-027 to CAT-035 |
| Static asset security | CAT-036 |
| Borrowing rules | CIRC-001 to CIRC-010, CIRC-026 to CIRC-030 |
| Returns and renewals | CIRC-011 to CIRC-019, LOANH-001 to LOANH-002 |
| Reservations | CIRC-020 to CIRC-025, CIRC-028, CIRC-032 |
| Favorites/wishlist | CIRC-034 to CIRC-040 |
| Users/admin member management/profile | USER-001 to USER-020 |
| Fines and payments | FINE-001 to FINE-016 |
| Notifications/device tokens | NOTIF-001 to NOTIF-008, DASH-003 |
| Blogs/videos/content | CONTENT-001 to CONTENT-006 |
| Settings and Google Sheet sync | SET-001 to SET-008, SYNC-001 to SYNC-003 |
| Dashboard | DASH-001 to DASH-002 |
| API contracts and middleware | API-001 to API-008 |
| Security hardening | SEC-001 to SEC-006, AUTH-020 to AUTH-023 |
| Performance/concurrency/resilience | PERF-001 to PERF-004, RES-001 to RES-004, CIRC-009, DB-001 |
| Accessibility/responsive/compatibility | A11Y-001 to A11Y-003, RESP-001 to RESP-002, COMP-001 to COMP-002 |
| Localization/timezone/data integrity | L10N-001 to L10N-002, DB-001 to DB-003 |
