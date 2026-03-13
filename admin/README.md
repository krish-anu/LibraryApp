# Library Admin Portal

A full-stack Next.js admin portal for library management with Supabase database and Asgardeo authentication.

## Features

- **Dashboard**: Overview of library statistics, most borrowed books, and recent fines
- **Book Inventory**: Manage books with CRUD operations, filtering, and pagination
- **User Management**: Manage library members with create, edit, and soft delete
- **Fines & Penalties**: Track and manage fines with tabs for all/unpaid/paid
- **Settings**: Configure loan rules, fine rates, and library information

## Tech Stack

- **Framework**: Next.js 16+ with App Router
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Asgardeo OAuth 2.0
- **Styling**: Tailwind CSS v4
- **Charts**: Recharts
- **Icons**: Lucide React
- **State Management**: Zustand

## Getting Started

### 1. Set up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to the SQL Editor and run the schema in `supabase/schema.sql`
3. Copy your project URL and keys from Settings > API

### 2. Set up Asgardeo

1. Create an account at [asgardeo.io](https://asgardeo.io)
2. Create a new application (Traditional Web Application)
3. Configure the callback URL: `http://localhost:3000/api/auth/callback`
4. Copy the Client ID and Client Secret

### 3. Configure Environment Variables

Copy `.env.local.example` to `.env.local` and fill in your credentials:

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your-supabase-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# Asgardeo Authentication
NEXT_PUBLIC_ASGARDEO_CLIENT_ID=your-asgardeo-client-id
ASGARDEO_CLIENT_SECRET=your-asgardeo-client-secret
NEXT_PUBLIC_ASGARDEO_BASE_URL=https://api.asgardeo.io/t/your-org

# Database
DATABASE_URL=postgres://...
# If local or hosted cert verification fails (SELF_SIGNED_CERT_IN_CHAIN), use:
DB_SSL_MODE=no-verify
# If you add DB_SSL_CA_CERT, switch to DB_SSL_MODE=verify or remove DB_SSL_MODE
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
├── components/
│   ├── layout/                # Layout components (Sidebar, Header)
│   └── ui/                    # Reusable UI components
├── lib/
│   ├── supabase/              # Supabase client configuration
│   ├── auth/                  # Auth context
│   ├── types.ts               # TypeScript interfaces
│   └── utils.ts               # Utility functions
├── supabase/
│   └── schema.sql             # Database schema
└── proxy.ts                   # Auth proxy
```

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
