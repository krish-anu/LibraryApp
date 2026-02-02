-- Library Admin Database Schema for Supabase
-- Run this script in Supabase SQL Editor to create all necessary tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Books table
CREATE TABLE IF NOT EXISTS books (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(255) NOT NULL,
  isbn VARCHAR(20),
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  description TEXT,
  cover_image_url TEXT,
  copies_owned INTEGER DEFAULT 1,
  copies_available INTEGER DEFAULT 1,
  status VARCHAR(50) DEFAULT 'available',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  membership_id VARCHAR(50) UNIQUE,
  phone VARCHAR(20),
  address TEXT,
  status VARCHAR(50) DEFAULT 'active',
  joined_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Loans table
CREATE TABLE IF NOT EXISTS loans (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  loan_date DATE DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  return_date DATE,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fines table
CREATE TABLE IF NOT EXISTS fines (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  loan_id UUID REFERENCES loans(id) ON DELETE SET NULL,
  book_id UUID REFERENCES books(id) ON DELETE SET NULL,
  amount DECIMAL(10, 2) NOT NULL,
  reason TEXT,
  status VARCHAR(50) DEFAULT 'unpaid',
  due_date DATE,
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reservations table
CREATE TABLE IF NOT EXISTS reservations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  reservation_date DATE DEFAULT CURRENT_DATE,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Settings table (singleton)
CREATE TABLE IF NOT EXISTS settings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  loan_period_days INTEGER DEFAULT 14,
  max_books_per_user INTEGER DEFAULT 5,
  grace_period_days INTEGER DEFAULT 2,
  daily_fine_rate DECIMAL(10, 2) DEFAULT 0.50,
  max_fine_cap DECIMAL(10, 2) DEFAULT 25.00,
  block_on_unpaid_fines BOOLEAN DEFAULT true,
  fine_threshold DECIMAL(10, 2) DEFAULT 10.00,
  send_notifications BOOLEAN DEFAULT true,
  notification_days_before_due INTEGER DEFAULT 3,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_books_category ON books(category_id);
CREATE INDEX IF NOT EXISTS idx_books_status ON books(status);
CREATE INDEX IF NOT EXISTS idx_loans_user ON loans(user_id);
CREATE INDEX IF NOT EXISTS idx_loans_book ON loans(book_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);
CREATE INDEX IF NOT EXISTS idx_fines_user ON fines(user_id);
CREATE INDEX IF NOT EXISTS idx_fines_status ON fines(status);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Seed some initial categories
INSERT INTO categories (name, description) VALUES
  ('Fiction', 'Fictional literature including novels and short stories'),
  ('Non-Fiction', 'Factual books including biographies, history, and science'),
  ('Science Fiction', 'Science fiction and fantasy books'),
  ('Mystery', 'Mystery and thriller novels'),
  ('Romance', 'Romance and love stories'),
  ('Children', 'Books for children and young adults'),
  ('Reference', 'Reference materials and encyclopedias'),
  ('Self-Help', 'Self-help and personal development books')
ON CONFLICT DO NOTHING;

-- Insert default settings
INSERT INTO settings (
  loan_period_days,
  max_books_per_user,
  grace_period_days,
  daily_fine_rate,
  max_fine_cap,
  block_on_unpaid_fines,
  fine_threshold,
  send_notifications,
  notification_days_before_due
) VALUES (14, 5, 2, 0.50, 25.00, true, 10.00, true, 3)
ON CONFLICT DO NOTHING;

-- Function to auto-generate membership ID
CREATE OR REPLACE FUNCTION generate_membership_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.membership_id IS NULL THEN
    NEW.membership_id := 'LIB-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(NEXTVAL('membership_seq')::TEXT, 5, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create sequence for membership IDs
CREATE SEQUENCE IF NOT EXISTS membership_seq START 1;

-- Create trigger for auto-generating membership ID
DROP TRIGGER IF EXISTS set_membership_id ON users;
CREATE TRIGGER set_membership_id
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION generate_membership_id();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_books_updated_at ON books;
CREATE TRIGGER update_books_updated_at
  BEFORE UPDATE ON books
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_settings_updated_at ON settings;
CREATE TRIGGER update_settings_updated_at
  BEFORE UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
-- Enable RLS on all tables
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE fines ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create policies for service role (admin) access
CREATE POLICY "Service role can do everything on books" ON books FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role can do everything on users" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role can do everything on loans" ON loans FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role can do everything on fines" ON fines FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role can do everything on reservations" ON reservations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role can do everything on categories" ON categories FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role can do everything on settings" ON settings FOR ALL USING (true) WITH CHECK (true);
