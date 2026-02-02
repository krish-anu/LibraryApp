export interface Book {
  id: string;
  title: string;
  author: string;
  isbn?: string;
  category?: string;
  category_id?: string;
  description?: string;
  image?: string;
  cover_image_url?: string;
  copies_owned: number;
  copies_available: number;
  status: 'available' | 'borrowed' | 'reserved' | 'maintenance' | 'checked_out';
  created_at: string;
  updated_at: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  membership_id?: string;
  phone?: string;
  address?: string;
  status: 'active' | 'inactive' | 'suspended';
  joined_date?: string;
  created_at: string;
  updated_at: string;
}

export interface Loan {
  id: string;
  user_id: string;
  book_id: string;
  loan_date: string;
  due_date: string;
  return_date?: string;
  status: 'active' | 'returned' | 'overdue';
  created_at: string;
}

export interface Fine {
  id: string;
  user_id: string;
  loan_id?: string;
  book_id?: string;
  amount: number;
  reason: string;
  status: 'paid' | 'unpaid' | 'waived';
  due_date?: string;
  paid_date?: string;
  created_at: string;
}

export interface Reservation {
  id: string;
  user_id: string;
  book_id: string;
  reservation_date: string;
  status: 'pending' | 'fulfilled' | 'cancelled';
  created_at: string;
}

export interface Category {
  id: string;
  name: string;
  description?: string;
  image?: string;
  book_count?: number;
}

export interface Settings {
  id: string;
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

export interface DashboardStats {
  activeUsers: number;
  totalInventory: number;
  pendingFines: number;
  avgCheckoutTime: number;
  userGrowth: number;
  inventoryGrowth: number;
  fineCount: number;
  checkoutImprovement: number;
}

export interface BookWithStats extends Book {
  circulation_count?: number;
}

export interface UserWithStats extends User {
  active_loans?: number;
  total_fines?: number;
}

export interface FineWithDetails extends Fine {
  user?: User;
  book?: Book;
}
