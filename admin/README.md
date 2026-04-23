# Library Admin Portal

 A full-stack Next.js admin portal for library management with Firestore data, Firebase Storage for media, and Asgardeo authentication.

## Features

- **Dashboard**: Overview of library statistics, most borrowed books, and recent fines
- **Book Inventory**: Manage books with CRUD operations, filtering, and pagination
- **User Management**: Manage library members with create, edit, and soft delete
- **Fines & Penalties**: Track and manage fines with tabs for all/unpaid/paid
- **Settings**: Configure loan rules, fine rates, and library information

## Tech Stack

- **Framework**: Next.js 16+ with App Router
- **Database**: Firebase Firestore
- **Cloud Storage**: Firebase Storage
- **Authentication**: Asgardeo OAuth 2.0
- **Styling**: Tailwind CSS v4
- **Charts**: Recharts
- **Icons**: Lucide React
- **State Management**: Zustand

## Architecture

- **Gateway Layer**: `app/api/*` route handlers now act as a stable API gateway surface.
- **Service Layer**: Domain logic lives in `services/*` modules organized by bounded context.
- **Data Access**: DB/auth/storage integrations are encapsulated per service domain.

## Getting Started

### 1. Set up Firebase

1. Create a Firebase project.
2. Enable Cloud Storage for the project.
3. Create a service account with Storage access and download the credentials.
4. Copy the project ID, client email, private key, and default storage bucket name.

### 2. Set up Asgardeo

1. Create an account at [asgardeo.io](https://asgardeo.io)
2. Create a new application (Traditional Web Application)
3. Configure the callback URL: `http://localhost:3000/api/auth/callback`
4. Copy the Client ID and Client Secret

### 3. Configure Environment Variables

For local development, copy `.env.local.example` to `.env.local` and fill in your credentials:

```bash
cp .env.local.example .env.local
```

For production builds, copy `.env.production.example` to `.env.production`:

```bash
cp .env.production.example .env.production
```

Real env files are ignored by Git. Keep secrets in `.env.local`,
`.env.production`, or your deployment secret manager.

```env
# Firebase Admin
LIBRARY_API_BASE_URL=http://127.0.0.1:8000
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_SERVICE_ACCOUNT_JSON=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# Asgardeo Authentication
ASGARDEO_CLIENT_ID=
ASGARDEO_CLIENT_SECRET=
ASGARDEO_AUTHORIZE_ENDPOINT=https://api.<region>.asgardeo.io/t/<org-name>/oauth2/authorize
ASGARDEO_TOKEN_ENDPOINT=https://api.<region>.asgardeo.io/t/<org-name>/oauth2/token
ASGARDEO_USERINFO_ENDPOINT=https://api.<region>.asgardeo.io/t/<org-name>/oauth2/userinfo
ASGARDEO_LOGOUT_ENDPOINT=https://api.<region>.asgardeo.io/t/<org-name>/oidc/logout
```

### 4. Install Dependencies

```bash
npm install
```

### 5. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the admin portal.

## Project Structure

```
admin/
├── app/
│   ├── (dashboard)/           # Protected dashboard routes
│   │   ├── dashboard/         # Main dashboard page
│   │   ├── books/             # Book inventory management
│   │   ├── users/             # User management
│   │   ├── fines/             # Fines & penalties
│   │   └── settings/          # Library settings
│   ├── api/                   # API routes
│   │   ├── auth/              # Authentication endpoints
│   │   ├── books/             # Books CRUD
│   │   ├── users/             # Users CRUD
│   │   ├── fines/             # Fines CRUD
│   │   ├── categories/        # Categories list
│   │   ├── dashboard/         # Dashboard stats
│   │   └── settings/          # Settings management
│   ├── login/                 # Login page
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── services/                  # Domain service modules (microservices-oriented)
│   ├── identity/              # Auth and session service
│   ├── catalog/               # Books and categories service
│   ├── members/               # User/member service
│   ├── fines/                 # Fine and payment service
│   ├── loans/                 # Loan renewal service
│   ├── config/                # Settings/config service
│   ├── analytics/             # Dashboard aggregation service
│   └── storage/               # Firebase Storage service
├── components/
│   ├── layout/                # Layout components (Sidebar, Header)
│   └── ui/                    # Reusable UI components
├── lib/
│   ├── firebase/              # Firebase Admin helpers
│   ├── auth/                  # Auth context
│   ├── types.ts               # TypeScript interfaces
│   └── utils.ts               # Utility functions
└── proxy.ts                   # Auth proxy
```

## Data Model

The admin app now stores data in Firestore collections such as `books`, `categories`, `users`, `loans`, `fines`, `finePayments`, and `settings`.
Default settings and categories are created automatically when the app first reads them.

## API Endpoints

### Authentication

- `GET /api/auth/callback` - OAuth callback handler
- `GET /api/auth/logout` - Logout and clear session
- `GET /api/auth/me` - Get current user info

### Books

- `GET /api/books` - List books (with pagination & filters)
- `POST /api/books` - Create new book
- `GET /api/books/[id]` - Get single book
- `PUT /api/books/[id]` - Update book
- `DELETE /api/books/[id]` - Delete book

### Users

- `GET /api/users` - List users (with pagination & filters)
- `POST /api/users` - Create new user
- `GET /api/users/[id]` - Get user with stats
- `PUT /api/users/[id]` - Update user
- `DELETE /api/users/[id]` - Soft delete user

### Fines

- `GET /api/fines` - List fines (with pagination & filters)
- `POST /api/fines` - Create manual fine
- `PUT /api/fines/[id]` - Update fine (mark paid/waived)
- `DELETE /api/fines/[id]` - Delete fine

### Other

- `GET /api/dashboard` - Dashboard statistics
- `GET /api/categories` - List categories
- `GET /api/settings` - Get settings
- `PUT /api/settings` - Update settings

## Deployment

### Vercel (Recommended)

1. Push your code to GitHub
2. Connect to Vercel and import the repository
3. Add environment variables in Vercel dashboard
4. Deploy!

### Other Platforms

Build the production version:

```bash
npm run build
npm start
```

## License

MIT
