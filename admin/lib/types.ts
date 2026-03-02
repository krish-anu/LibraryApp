// Based on server/app/models - matches existing PostgreSQL tables

export interface Book {
  id: string;
  title: string;
  author: string;
  category_id?: string;
  description?: string;
  rating?: number;
  publication_year?: number;
  copies_owned: number;
  copies_available?: number;
  status?: string;
  image?: string;
  language?: string;
  pages?: number;
  rating_count?: number;
  // Joined fields
  category?: string;
}

export interface User {
  id: string;
  member_id?: string;
  name: string;
  email: string;
  phone?: string;
  address?: string;
  profile_image?: string;
  joined_date?: string;
  created_at?: string;
  updated_at?: string;
}

export interface Loan {
  id: string;
  book_id: string;
  member_id: string;
  loan_date: string;
  returned_date?: string;
  // Joined fields
  book?: Book;
  member?: User;
}

export interface Fine {
  id: string;
  member_id: string;
  loan_id?: string;
  fine_date: string;
  fine_amount: number;
  status?: "unpaid" | "paid" | "waived" | string;
  reason?: string | null;
  due_date?: string | null;
  paid_at?: string | null;
  payment_method?: string | null;
  created_at?: string;
  updated_at?: string;
  // Joined fields
  member?: User;
  loan?: Loan;
}

export interface Reservation {
  id: string;
  book_id: string;
  member_id: string;
  reserved_at: string;
  status?: string;
  // Joined fields
  book?: Book;
  member?: User;
}

export interface Category {
  id: string;
  name: string;
  image_url?: string;
  book_count?: number;
}

export interface Author {
  id: string;
  name: string;
}

export interface FinePayment {
  id: string;
  fine_id?: string;
  member_id?: string;
  payment_date: string;
  payment_amount: number;
  payment_method?: string | null;
  handled_by?: string | null;
  notes?: string | null;
  created_at?: string;
}

export interface DashboardStats {
  activeUsers: number;
  totalBooks: number;
  totalLoans: number;
  pendingFines: number;
  recentLoans: Loan[];
  topBooks: { book: Book; count: number }[];
}

export interface Settings {
  loan_period_days: number;
  max_books_per_user: number;
  grace_period_days: number;
  daily_fine_rate: number;
  max_fine_cap: number;
  block_on_unpaid_fines: boolean;
  fine_threshold: number;
  send_notifications: boolean;
  notification_days_before_due: number;
}
