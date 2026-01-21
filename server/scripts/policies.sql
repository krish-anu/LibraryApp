-- Enable RLS on all tables
ALTER TABLE authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_author ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fines ENABLE ROW LEVEL SECURITY;
ALTER TABLE fine_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;

-- Public catalog tables (read-only)
-- authors
CREATE POLICY "Public read authors"
ON authors
FOR SELECT
USING (true);

-- books
CREATE POLICY "Public read books"
ON books
FOR SELECT
USING (true);

-- categories
CREATE POLICY "Public read categories"
ON categories
FOR SELECT
USING (true);

-- book_author
CREATE POLICY "Public read book_author"
ON book_author
FOR SELECT
USING (true);

-- Users table (each user sees only themselves)
-- Read own profile
CREATE POLICY "Users can read own profile"
ON users
FOR SELECT
USING (auth.uid()::text = id);

-- Update own profile
CREATE POLICY "Users can update own profile"
ON users
FOR UPDATE
USING (auth.uid()::text = id)
WITH CHECK (auth.uid()::text = id);

-- Insert own profile (Crucial for signup flows)
CREATE POLICY "Users can insert own profile"
ON users
FOR INSERT
WITH CHECK (auth.uid()::text = id);

-- Loans (member-specific)
-- Read own loans
CREATE POLICY "Members read own loans"
ON loans
FOR SELECT
USING (auth.uid()::text = member_id);

-- Insert own loan (optional – usually staff does this)
CREATE POLICY "Members insert own loans"
ON loans
FOR INSERT
WITH CHECK (auth.uid()::text = member_id);

-- Reservations
-- Read own reservations
CREATE POLICY "Members read own reservations"
ON reservations
FOR SELECT
USING (auth.uid()::text = member_id);

-- Create reservation
CREATE POLICY "Members create reservations"
ON reservations
FOR INSERT
WITH CHECK (auth.uid()::text = member_id);

-- Update own reservation
CREATE POLICY "Members update own reservations"
ON reservations
FOR UPDATE
USING (auth.uid()::text = member_id)
WITH CHECK (auth.uid()::text = member_id);

-- Fines & Payments
-- View own fines
CREATE POLICY "Members read own fines"
ON fines
FOR SELECT
USING (auth.uid()::text = member_id);

-- View own fine payments
CREATE POLICY "Members read own fine payments"
ON fine_payments
FOR SELECT
USING (auth.uid()::text = member_id);

-- Interactions (likes, views, ratings, etc.)
-- Read own interactions
CREATE POLICY "Users read own interactions"
ON interactions
FOR SELECT
USING (auth.uid()::text = user_id);

-- Insert interaction
CREATE POLICY "Users create interactions"
ON interactions
FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- Delete own interaction
CREATE POLICY "Users delete own interactions"
ON interactions
FOR DELETE
USING (auth.uid()::text = user_id);
