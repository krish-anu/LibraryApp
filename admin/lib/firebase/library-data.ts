import type { Book, Category, Fine, Settings, User } from "@/lib/types";
import { getFirebaseFirestore } from "./admin";

const COLLECTIONS = {
  books: "books",
  categories: "categories",
  finePayments: "finePayments",
  fines: "fines",
  loans: "loans",
  settings: "settings",
  users: "users",
} as const;

const SETTINGS_DOC_ID = "library";
const ADMIN_RENEWAL_DAYS = 14;

const DEFAULT_SETTINGS: Settings = {
  loan_period_days: 14,
  max_books_per_user: 5,
  grace_period_days: 2,
  daily_fine_rate: 0.5,
  max_fine_cap: 25,
  block_on_unpaid_fines: true,
  fine_threshold: 10,
  send_notifications: true,
  notification_days_before_due: 3,
};

const DEFAULT_CATEGORIES: Category[] = [
  { id: "cat-fiction", name: "Fiction" },
  { id: "cat-non-fiction", name: "Non-Fiction" },
  { id: "cat-science-fiction", name: "Science Fiction" },
  { id: "cat-mystery", name: "Mystery" },
  { id: "cat-romance", name: "Romance" },
  { id: "cat-children", name: "Children" },
  { id: "cat-reference", name: "Reference" },
  { id: "cat-self-help", name: "Self-Help" },
];

type StoredBook = Book & {
  created_at?: string;
  updated_at?: string;
};

type StoredUser = User & {
  status?: string;
};

type StoredLoan = {
  id: string;
  book_id?: string;
  created_at?: string;
  due_date?: string;
  loan_date?: string;
  member_id?: string;
  return_date?: string;
  returned_date?: string;
  status?: string;
  updated_at?: string;
  user_id?: string;
};

type StoredFine = Fine & {
  amount?: number;
  created_at?: string;
  updated_at?: string;
  user_id?: string;
};

type StoredFinePayment = {
  id: string;
  created_at?: string;
  fine_id?: string;
  handled_by?: string | null;
  member_id?: string | null;
  notes?: string | null;
  payment_amount?: number;
  payment_date?: string;
  payment_method?: string | null;
};

export class ValidationError extends Error {}
export class NotFoundError extends Error {}
export class ConflictError extends Error {}

function firestore() {
  return getFirebaseFirestore();
}

function nowIso(): string {
  return new Date().toISOString();
}

function todayIso(): string {
  return nowIso().slice(0, 10);
}

function stripUndefined<T extends Record<string, unknown>>(value: T): T {
  return Object.fromEntries(
    Object.entries(value).filter(([, entry]) => entry !== undefined),
  ) as T;
}

function makeId(prefix: string): string {
  return `${prefix}${Math.floor(100000 + Math.random() * 900000)}`;
}

function makeMemberId(): string {
  return `MEM-${Date.now().toString(36).toUpperCase()}`;
}

function nonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

function toFiniteNumber(value: unknown): number | null {
  if (value === undefined || value === null || value === "") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function toFiniteInt(value: unknown): number | null {
  const parsed = toFiniteNumber(value);
  return parsed === null ? null : Math.trunc(parsed);
}

function normalizeTimestamp(value: unknown, fallback = nowIso()): string {
  if (typeof value === "string" && value.trim()) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed.toISOString();
    }
  }
  return fallback;
}

function normalizeDateOnly(value: unknown, fallback = todayIso()): string {
  if (typeof value === "string" && value.trim()) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed.toISOString().slice(0, 10);
    }
  }
  return fallback;
}

function diffDays(laterDate: string, earlierDate: string): number {
  const later = new Date(`${laterDate}T00:00:00.000Z`);
  const earlier = new Date(`${earlierDate}T00:00:00.000Z`);
  const diffMs = later.getTime() - earlier.getTime();
  return Math.max(0, Math.floor(diffMs / 86400000));
}

function addDays(dateValue: string, days: number): string {
  const parsed = new Date(`${dateValue}T00:00:00.000Z`);
  parsed.setUTCDate(parsed.getUTCDate() + days);
  return parsed.toISOString().slice(0, 10);
}

function compareDateDesc(left: string | undefined, right: string | undefined) {
  return normalizeTimestamp(
    right || "",
    "1970-01-01T00:00:00.000Z",
  ).localeCompare(normalizeTimestamp(left || "", "1970-01-01T00:00:00.000Z"));
}

function matchesSearch(
  values: Array<string | number | null | undefined>,
  search?: string | null,
) {
  if (!search) return true;
  const normalized = search.trim().toLowerCase();
  if (!normalized) return true;
  return values.some((value) =>
    String(value ?? "")
      .toLowerCase()
      .includes(normalized),
  );
}

async function getAllDocuments<T extends { id: string }>(
  collectionName: string,
): Promise<T[]> {
  const snapshot = await firestore().collection(collectionName).get();
  return snapshot.docs.map((doc) => ({
    ...(doc.data() as Omit<T, "id">),
    id: doc.id,
  })) as T[];
}

async function getDocumentById<T extends { id: string }>(
  collectionName: string,
  id: string,
): Promise<T | null> {
  const snapshot = await firestore().collection(collectionName).doc(id).get();
  if (!snapshot.exists) {
    return null;
  }

  return {
    ...(snapshot.data() as Omit<T, "id">),
    id: snapshot.id,
  } as T;
}

async function setDocument(
  collectionName: string,
  id: string,
  data: Record<string, unknown>,
  merge = false,
) {
  await firestore()
    .collection(collectionName)
    .doc(id)
    .set(stripUndefined({ ...data, id }), { merge });
}

async function deleteDocument(collectionName: string, id: string) {
  await firestore().collection(collectionName).doc(id).delete();
}

async function ensureSettingsDocument(): Promise<Settings & { id: string }> {
  const ref = firestore().collection(COLLECTIONS.settings).doc(SETTINGS_DOC_ID);
  const snapshot = await ref.get();

  if (!snapshot.exists) {
    const createdAt = nowIso();
    await ref.set({
      id: SETTINGS_DOC_ID,
      ...DEFAULT_SETTINGS,
      created_at: createdAt,
      updated_at: createdAt,
    });
  }

  const latestSnapshot = await ref.get();
  const data = latestSnapshot.data() || {};

  return {
    id: SETTINGS_DOC_ID,
    loan_period_days:
      toFiniteInt(data.loan_period_days) ?? DEFAULT_SETTINGS.loan_period_days,
    max_books_per_user:
      toFiniteInt(data.max_books_per_user) ??
      DEFAULT_SETTINGS.max_books_per_user,
    grace_period_days:
      toFiniteInt(data.grace_period_days) ?? DEFAULT_SETTINGS.grace_period_days,
    daily_fine_rate:
      toFiniteNumber(data.daily_fine_rate) ?? DEFAULT_SETTINGS.daily_fine_rate,
    max_fine_cap:
      toFiniteNumber(data.max_fine_cap) ?? DEFAULT_SETTINGS.max_fine_cap,
    block_on_unpaid_fines:
      typeof data.block_on_unpaid_fines === "boolean"
        ? data.block_on_unpaid_fines
        : DEFAULT_SETTINGS.block_on_unpaid_fines,
    fine_threshold:
      toFiniteNumber(data.fine_threshold) ?? DEFAULT_SETTINGS.fine_threshold,
    send_notifications:
      typeof data.send_notifications === "boolean"
        ? data.send_notifications
        : DEFAULT_SETTINGS.send_notifications,
    notification_days_before_due:
      toFiniteInt(data.notification_days_before_due) ??
      DEFAULT_SETTINGS.notification_days_before_due,
  };
}

async function ensureDefaultCategories() {
  const snapshot = await firestore()
    .collection(COLLECTIONS.categories)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    return;
  }

  const batch = firestore().batch();
  for (const category of DEFAULT_CATEGORIES) {
    batch.set(
      firestore().collection(COLLECTIONS.categories).doc(category.id),
      category,
    );
  }
  await batch.commit();
}

function normalizeCategory(category: Partial<Category> & { id: string }): Category {
  return {
    id: category.id,
    name: nonEmptyString(category.name) || "Uncategorized",
    image_url: nonEmptyString(category.image_url) || undefined,
    book_count: toFiniteInt(category.book_count) ?? undefined,
  };
}

function normalizeBook(
  book: Partial<StoredBook> & { id: string },
  categoriesById: Map<string, Category>,
): Book {
  const categoryId = nonEmptyString(book.category_id) || undefined;
  const copiesOwned = Math.max(0, toFiniteInt(book.copies_owned) ?? 0);
  const copiesAvailable = Math.max(
    0,
    toFiniteInt(book.copies_available) ?? copiesOwned,
  );

  return {
    id: book.id,
    title: nonEmptyString(book.title) || "",
    author: nonEmptyString(book.author) || "",
    category_id: categoryId,
    description: nonEmptyString(book.description) || undefined,
    rating: toFiniteNumber(book.rating) ?? undefined,
    publication_year: toFiniteInt(book.publication_year) ?? undefined,
    copies_owned: copiesOwned,
    copies_available: copiesAvailable,
    status: copiesAvailable > 0 ? "available" : "not_available",
    image: nonEmptyString(book.image) || undefined,
    language: nonEmptyString(book.language) || "English",
    pages: toFiniteInt(book.pages) ?? undefined,
    rating_count: toFiniteInt(book.rating_count) ?? 0,
    category: categoryId
      ? categoriesById.get(categoryId)?.name || undefined
      : nonEmptyString(book.category) || undefined,
  };
}

function normalizeUser(user: Partial<StoredUser> & { id: string }): User {
  return {
    id: user.id,
    member_id: nonEmptyString(user.member_id) || undefined,
    name: nonEmptyString(user.name) || "",
    email: nonEmptyString(user.email) || "",
    phone: nonEmptyString(user.phone) || undefined,
    address: nonEmptyString(user.address) || undefined,
    profile_image: nonEmptyString(user.profile_image) || undefined,
    joined_date: normalizeDateOnly(user.joined_date, todayIso()),
    created_at: normalizeTimestamp(user.created_at),
    updated_at: normalizeTimestamp(user.updated_at),
  };
}

function getLoanMemberId(loan: Partial<StoredLoan>): string | null {
  return nonEmptyString(loan.member_id) || nonEmptyString(loan.user_id);
}

function getLoanDueDate(loan: Partial<StoredLoan>): string | null {
  return (
    nonEmptyString(loan.due_date) ||
    nonEmptyString(loan.return_date) ||
    nonEmptyString(loan.returned_date)
  );
}

function normalizeFineStatus(value: unknown): "unpaid" | "paid" | "waived" {
  const normalized = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (normalized === "paid" || normalized === "waived") {
    return normalized;
  }
  return "unpaid";
}

function normalizeFineBase(fine: Partial<StoredFine> & { id: string }): Fine {
  return {
    id: fine.id,
    member_id:
      nonEmptyString(fine.member_id) || nonEmptyString(fine.user_id) || "",
    loan_id: nonEmptyString(fine.loan_id) || undefined,
    fine_date: normalizeDateOnly(fine.fine_date, todayIso()),
    fine_amount:
      toFiniteNumber(fine.fine_amount) ?? toFiniteNumber(fine.amount) ?? 0,
    status: normalizeFineStatus(fine.status),
    reason: nonEmptyString(fine.reason) || null,
    due_date: nonEmptyString(fine.due_date) || null,
    paid_at: nonEmptyString(fine.paid_at) || null,
    payment_method: nonEmptyString(fine.payment_method) || null,
    created_at: normalizeTimestamp(fine.created_at),
    updated_at: normalizeTimestamp(fine.updated_at),
  };
}

function normalizeFinePayment(
  payment: Partial<StoredFinePayment> & { id: string },
): StoredFinePayment {
  return {
    id: payment.id,
    fine_id: nonEmptyString(payment.fine_id) || undefined,
    member_id: nonEmptyString(payment.member_id) || undefined,
    payment_date: normalizeDateOnly(payment.payment_date, todayIso()),
    payment_amount: toFiniteNumber(payment.payment_amount) ?? 0,
    payment_method: nonEmptyString(payment.payment_method) || "physical",
    handled_by: nonEmptyString(payment.handled_by),
    notes: nonEmptyString(payment.notes),
    created_at: normalizeTimestamp(payment.created_at),
  };
}

async function getCategoryMap(): Promise<Map<string, Category>> {
  const categories = await listCategoriesData();
  return new Map(categories.map((category) => [category.id, category]));
}

type FineWithDetails = Fine & {
  book_title?: string;
  payment_amount?: number;
  payment_count?: number;
  payment_date?: string;
  payment_handled_by?: string;
  payment_notes?: string;
  total_fine_amount?: number;
  total_paid?: number;
  user_email?: string;
  user_name?: string;
  user_total_due?: number;
};

function buildFineDetails(
  fines: StoredFine[],
  users: StoredUser[],
  loans: StoredLoan[],
  books: StoredBook[],
  payments: StoredFinePayment[],
): FineWithDetails[] {
  const usersById = new Map(users.map((user) => [user.id, normalizeUser(user)]));
  const loansById = new Map(loans.map((loan) => [loan.id, loan]));
  const booksById = new Map(books.map((book) => [book.id, book]));

  const paymentsByFineId = new Map<string, StoredFinePayment[]>();
  for (const payment of payments.map(normalizeFinePayment)) {
    if (!payment.fine_id) continue;
    const paymentList = paymentsByFineId.get(payment.fine_id) || [];
    paymentList.push(payment);
    paymentsByFineId.set(payment.fine_id, paymentList);
  }

  for (const paymentList of paymentsByFineId.values()) {
    paymentList.sort((left, right) =>
      compareDateDesc(
        left.created_at || left.payment_date,
        right.created_at || right.payment_date,
      ),
    );
  }

  const built = fines.map((fine) => {
    const normalizedFine = normalizeFineBase(fine);
    const finePayments = paymentsByFineId.get(normalizedFine.id) || [];
    const latestPayment = finePayments[0];
    const totalPaid = finePayments.reduce(
      (sum, payment) => sum + (toFiniteNumber(payment.payment_amount) ?? 0),
      0,
    );
    const loan = normalizedFine.loan_id
      ? loansById.get(normalizedFine.loan_id)
      : undefined;
    const book = loan?.book_id ? booksById.get(loan.book_id) : undefined;
    const user = normalizedFine.member_id
      ? usersById.get(normalizedFine.member_id)
      : undefined;

    return {
      ...normalizedFine,
      user_name: user?.name,
      user_email: user?.email,
      book_title: nonEmptyString(book?.title) || undefined,
      payment_date: latestPayment?.payment_date,
      payment_amount: toFiniteNumber(latestPayment?.payment_amount) ?? undefined,
      payment_handled_by: nonEmptyString(latestPayment?.handled_by) || undefined,
      payment_notes: nonEmptyString(latestPayment?.notes) || undefined,
      total_paid: Number(totalPaid.toFixed(2)),
      payment_count: finePayments.length,
      total_fine_amount: Number(
        (normalizedFine.fine_amount + totalPaid).toFixed(2),
      ),
    } satisfies FineWithDetails;
  });

  const userTotals = new Map<string, number>();
  for (const fine of built) {
    if (fine.status !== "unpaid" || !fine.member_id) continue;
    userTotals.set(
      fine.member_id,
      Number((userTotals.get(fine.member_id) || 0) + fine.fine_amount),
    );
  }

  return built.map((fine) => ({
    ...fine,
    user_total_due: fine.member_id
      ? Number((userTotals.get(fine.member_id) || 0).toFixed(2))
      : 0,
  }));
}

async function loadFineContext() {
  const [fines, users, loans, books, payments] = await Promise.all([
    getAllDocuments<StoredFine>(COLLECTIONS.fines),
    getAllDocuments<StoredUser>(COLLECTIONS.users),
    getAllDocuments<StoredLoan>(COLLECTIONS.loans),
    getAllDocuments<StoredBook>(COLLECTIONS.books),
    getAllDocuments<StoredFinePayment>(COLLECTIONS.finePayments),
  ]);

  return { fines, users, loans, books, payments };
}

export async function syncOverdueLoanFines() {
  const [settings, loans, fines, finePayments] = await Promise.all([
    ensureSettingsDocument(),
    getAllDocuments<StoredLoan>(COLLECTIONS.loans),
    getAllDocuments<StoredFine>(COLLECTIONS.fines),
    getAllDocuments<StoredFinePayment>(COLLECTIONS.finePayments),
  ]);

  if (loans.length === 0) {
    return;
  }

  const today = todayIso();
  const normalizedFines = fines.map(normalizeFineBase);
  const fineById = new Map(normalizedFines.map((fine) => [fine.id, fine]));

  const cyclePaidByLoanAndDueDate = new Map<string, number>();
  for (const payment of finePayments.map(normalizeFinePayment)) {
    if (!payment.fine_id) continue;
    const fine = fineById.get(payment.fine_id);
    if (!fine?.loan_id || !fine.due_date) continue;
    const key = `${fine.loan_id}__${fine.due_date}`;
    cyclePaidByLoanAndDueDate.set(
      key,
      (cyclePaidByLoanAndDueDate.get(key) || 0) +
        (toFiniteNumber(payment.payment_amount) ?? 0),
    );
  }

  const batch = firestore().batch();
  let pendingWrites = 0;
  const dailyFineRate = Math.max(0.01, settings.daily_fine_rate);
  const maxFineCap = Math.max(settings.max_fine_cap, dailyFineRate);

  for (const loan of loans) {
    const memberId = getLoanMemberId(loan);
    const dueDate = getLoanDueDate(loan);
    if (!loan.id || !memberId || !dueDate) continue;
    if (diffDays(today, dueDate) <= 0) continue;

    const overdueDays = diffDays(today, dueDate);
    const computedAmount = Math.min(overdueDays * dailyFineRate, maxFineCap);
    const cycleKey = `${loan.id}__${dueDate}`;
    const totalPaid = cyclePaidByLoanAndDueDate.get(cycleKey) || 0;
    const remainingAmount = Number(
      Math.max(0, computedAmount - totalPaid).toFixed(2),
    );
    const status = remainingAmount > 0 ? "unpaid" : "paid";

    const existingFine = normalizedFines.find(
      (fine) =>
        fine.loan_id === loan.id &&
        normalizeDateOnly(fine.due_date || fine.fine_date, dueDate) === dueDate &&
        normalizeFineStatus(fine.status) === "unpaid",
    );

    if (existingFine) {
      batch.set(
        firestore().collection(COLLECTIONS.fines).doc(existingFine.id),
        stripUndefined({
          id: existingFine.id,
          member_id: memberId,
          loan_id: loan.id,
          fine_date: existingFine.fine_date || today,
          fine_amount: remainingAmount,
          status,
          reason: existingFine.reason || "Overdue return",
          due_date: dueDate,
          paid_at: status === "paid" ? existingFine.paid_at || nowIso() : null,
          payment_method:
            status === "paid"
              ? existingFine.payment_method || "physical"
              : existingFine.payment_method || null,
          created_at: existingFine.created_at || nowIso(),
          updated_at: nowIso(),
        }),
        { merge: true },
      );
      pendingWrites += 1;
      continue;
    }

    if (remainingAmount <= 0) {
      continue;
    }

    const fineId = makeId("f");
    batch.set(firestore().collection(COLLECTIONS.fines).doc(fineId), {
      id: fineId,
      member_id: memberId,
      loan_id: loan.id,
      fine_date: today,
      fine_amount: remainingAmount,
      status: "unpaid",
      reason: "Overdue return",
      due_date: dueDate,
      paid_at: null,
      payment_method: null,
      created_at: nowIso(),
      updated_at: nowIso(),
    });
    pendingWrites += 1;
  }

  if (pendingWrites > 0) {
    await batch.commit();
  }
}

export async function listCategoriesData(): Promise<Category[]> {
  await ensureDefaultCategories();
  const categories = await getAllDocuments<Category>(COLLECTIONS.categories);
  return categories
    .map(normalizeCategory)
    .sort((left, right) => left.name.localeCompare(right.name));
}

export async function listBooksData(options: {
  category?: string | null;
  limit?: number;
  page?: number;
  search?: string | null;
  status?: string | null;
}) {
  const page = Math.max(1, options.page || 1);
  const limit = Math.min(100, Math.max(1, options.limit || 10));
  const categoriesById = await getCategoryMap();
  const books = (await getAllDocuments<StoredBook>(COLLECTIONS.books)).map(
    (book) => normalizeBook(book, categoriesById),
  );

  const filtered = books
    .filter((book) => {
      if (options.category && options.category !== "all") {
        return book.category_id === options.category;
      }
      return true;
    })
    .filter((book) =>
      matchesSearch([book.title, book.author], options.search),
    )
    .filter((book) => {
      if (!options.status) return true;
      if (options.status === "available") {
        return (book.copies_available ?? book.copies_owned) > 0;
      }
      if (options.status === "not_available") {
        return (book.copies_available ?? book.copies_owned) <= 0;
      }
      return (book.status || "").toLowerCase() === options.status.toLowerCase();
    })
    .sort((left, right) => left.title.localeCompare(right.title));

  const total = filtered.length;
  const offset = (page - 1) * limit;

  return {
    data: filtered.slice(offset, offset + limit),
    totalCount: total,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

export async function getBookData(id: string): Promise<Book> {
  const categoriesById = await getCategoryMap();
  const book = await getDocumentById<StoredBook>(COLLECTIONS.books, id);
  if (!book) {
    throw new NotFoundError("Book not found");
  }
  return normalizeBook(book, categoriesById);
}

export async function createBookData(payload: Record<string, unknown>) {
  const title = nonEmptyString(payload.title);
  if (!title || title.length > 500) {
    throw new ValidationError("Title is required and must be 1-500 characters");
  }

  const rating = toFiniteNumber(payload.rating);
  if (rating !== null && (rating < 0 || rating > 5)) {
    throw new ValidationError("Rating must be between 0 and 5");
  }

  const publicationYear = toFiniteInt(payload.publication_year);
  if (
    publicationYear !== null &&
    (publicationYear < 0 || publicationYear > new Date().getFullYear() + 1)
  ) {
    throw new ValidationError("Invalid publication year");
  }

  const pages = toFiniteInt(payload.pages);
  if (pages !== null && (pages < 1 || pages > 100000)) {
    throw new ValidationError("Pages must be between 1 and 100000");
  }

  const copiesOwned = toFiniteInt(payload.copies_owned) ?? 1;
  if (copiesOwned < 0 || copiesOwned > 10000) {
    throw new ValidationError("Copies owned must be between 0 and 10000");
  }

  const id = makeId("b");
  const createdAt = nowIso();

  await setDocument(
    COLLECTIONS.books,
    id,
    {
      title,
      author: nonEmptyString(payload.author) || "",
      category_id: nonEmptyString(payload.category_id) || null,
      description: nonEmptyString(payload.description) || null,
      rating: rating ?? null,
      publication_year: publicationYear ?? null,
      copies_owned: copiesOwned,
      copies_available: copiesOwned,
      image: nonEmptyString(payload.image) || null,
      language: nonEmptyString(payload.language) || "English",
      pages: pages ?? null,
      rating_count: 0,
      created_at: createdAt,
      updated_at: createdAt,
    },
    false,
  );

  return getBookData(id);
}

export async function updateBookData(
  id: string,
  payload: Record<string, unknown>,
) {
  const existing = await getDocumentById<StoredBook>(COLLECTIONS.books, id);
  if (!existing) {
    throw new NotFoundError("Book not found");
  }

  const updates: Record<string, unknown> = {
    updated_at: nowIso(),
  };

  if (Object.prototype.hasOwnProperty.call(payload, "title")) {
    const title = nonEmptyString(payload.title);
    if (!title || title.length > 500) {
      throw new ValidationError(
        "Title is required and must be 1-500 characters",
      );
    }
    updates.title = title;
  }

  if (Object.prototype.hasOwnProperty.call(payload, "author")) {
    updates.author = nonEmptyString(payload.author) || "";
  }
  if (Object.prototype.hasOwnProperty.call(payload, "category_id")) {
    updates.category_id = nonEmptyString(payload.category_id) || null;
  }
  if (Object.prototype.hasOwnProperty.call(payload, "description")) {
    updates.description = nonEmptyString(payload.description) || null;
  }
  if (Object.prototype.hasOwnProperty.call(payload, "rating")) {
    const rating = toFiniteNumber(payload.rating);
    if (rating !== null && (rating < 0 || rating > 5)) {
      throw new ValidationError("Rating must be between 0 and 5");
    }
    updates.rating = rating;
  }
  if (Object.prototype.hasOwnProperty.call(payload, "publication_year")) {
    const publicationYear = toFiniteInt(payload.publication_year);
    if (
      publicationYear !== null &&
      (publicationYear < 0 || publicationYear > new Date().getFullYear() + 1)
    ) {
      throw new ValidationError("Invalid publication year");
    }
    updates.publication_year = publicationYear;
  }
  if (Object.prototype.hasOwnProperty.call(payload, "copies_owned")) {
    const copiesOwned = toFiniteInt(payload.copies_owned);
    if (copiesOwned === null || copiesOwned < 0 || copiesOwned > 10000) {
      throw new ValidationError("Copies owned must be between 0 and 10000");
    }
    updates.copies_owned = copiesOwned;
    updates.copies_available = copiesOwned;
  }
  if (Object.prototype.hasOwnProperty.call(payload, "image")) {
    updates.image = nonEmptyString(payload.image) || null;
  }
  if (Object.prototype.hasOwnProperty.call(payload, "language")) {
    updates.language = nonEmptyString(payload.language) || "English";
  }
  if (Object.prototype.hasOwnProperty.call(payload, "pages")) {
    const pages = toFiniteInt(payload.pages);
    if (pages !== null && (pages < 1 || pages > 100000)) {
      throw new ValidationError("Pages must be between 1 and 100000");
    }
    updates.pages = pages;
  }

  await setDocument(COLLECTIONS.books, id, updates, true);
  return getBookData(id);
}

export async function deleteBookData(id: string) {
  const existing = await getDocumentById<StoredBook>(COLLECTIONS.books, id);
  if (!existing) {
    throw new NotFoundError("Book not found");
  }
  await deleteDocument(COLLECTIONS.books, id);
  return { success: true };
}

export async function listUsersData(options: {
  limit?: number;
  page?: number;
  search?: string | null;
  status?: string | null;
}) {
  const page = Math.max(1, options.page || 1);
  const limit = Math.min(100, Math.max(1, options.limit || 10));
  const users = (await getAllDocuments<StoredUser>(COLLECTIONS.users))
    .filter((user) => {
      if (!options.status) return true;
      return (user.status || "active").toLowerCase() === options.status.toLowerCase();
    })
    .map(normalizeUser)
    .filter((user) =>
      matchesSearch([user.name, user.email, user.member_id], options.search),
    )
    .sort((left, right) => left.name.localeCompare(right.name));

  const total = users.length;
  const offset = (page - 1) * limit;

  return {
    data: users.slice(offset, offset + limit),
    totalCount: total,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

export async function createUserData(payload: Record<string, unknown>) {
  const name = nonEmptyString(payload.name);
  if (!name || name.length > 200) {
    throw new ValidationError("Name is required and must be 1-200 characters");
  }

  const email = nonEmptyString(payload.email);
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ValidationError("Valid email is required");
  }

  const phone = nonEmptyString(payload.phone);
  if (phone && (phone.length > 20 || !/^[+\d\s()-]+$/.test(phone))) {
    throw new ValidationError("Invalid phone number format");
  }

  const address = nonEmptyString(payload.address);
  if (address && address.length > 500) {
    throw new ValidationError("Address must be under 500 characters");
  }

  const existingUsers = await getAllDocuments<StoredUser>(COLLECTIONS.users);
  const duplicateEmail = existingUsers.some(
    (user) => (user.email || "").toLowerCase() === email.toLowerCase(),
  );
  if (duplicateEmail) {
    throw new ConflictError("A user with this email already exists");
  }

  const id = makeId("u");
  const createdAt = nowIso();

  await setDocument(
    COLLECTIONS.users,
    id,
    {
      member_id: makeMemberId(),
      name,
      email,
      phone: phone || null,
      address: address || null,
      joined_date: todayIso(),
      created_at: createdAt,
      updated_at: createdAt,
    },
    false,
  );

  const created = await getDocumentById<StoredUser>(COLLECTIONS.users, id);
  if (!created) {
    throw new NotFoundError("User not found");
  }
  return normalizeUser(created);
}

export async function getUserWithStatsData(id: string) {
  const user = await getDocumentById<StoredUser>(COLLECTIONS.users, id);
  if (!user) {
    throw new NotFoundError("User not found");
  }

  const [loans, fines] = await Promise.all([
    getAllDocuments<StoredLoan>(COLLECTIONS.loans),
    getAllDocuments<StoredFine>(COLLECTIONS.fines),
  ]);

  const activeLoans = loans.filter(
    (loan) =>
      getLoanMemberId(loan) === id &&
      !nonEmptyString(loan.returned_date) &&
      !nonEmptyString(loan.return_date),
  ).length;

  const totalFines = fines
    .map(normalizeFineBase)
    .filter((fine) => fine.member_id === id && fine.status === "unpaid")
    .reduce((sum, fine) => sum + fine.fine_amount, 0);

  return {
    ...normalizeUser(user),
    active_loans: activeLoans,
    total_fines: Number(totalFines.toFixed(2)),
  };
}

export async function updateUserData(
  id: string,
  payload: Record<string, unknown>,
) {
  const existing = await getDocumentById<StoredUser>(COLLECTIONS.users, id);
  if (!existing) {
    throw new NotFoundError("User not found");
  }

  const updates: Record<string, unknown> = {
    updated_at: nowIso(),
  };

  if (Object.prototype.hasOwnProperty.call(payload, "name")) {
    const name = nonEmptyString(payload.name);
    if (!name || name.length > 200) {
      throw new ValidationError("Name is required and must be 1-200 characters");
    }
    updates.name = name;
  }

  if (Object.prototype.hasOwnProperty.call(payload, "email")) {
    const email = nonEmptyString(payload.email);
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new ValidationError("Valid email is required");
    }

    const existingUsers = await getAllDocuments<StoredUser>(COLLECTIONS.users);
    const duplicateEmail = existingUsers.some(
      (user) =>
        user.id !== id &&
        (user.email || "").toLowerCase() === email.toLowerCase(),
    );
    if (duplicateEmail) {
      throw new ConflictError("A user with this email already exists");
    }
    updates.email = email;
  }

  if (Object.prototype.hasOwnProperty.call(payload, "phone")) {
    const phone = nonEmptyString(payload.phone);
    if (phone && (phone.length > 20 || !/^[+\d\s()-]+$/.test(phone))) {
      throw new ValidationError("Invalid phone number format");
    }
    updates.phone = phone || null;
  }

  if (Object.prototype.hasOwnProperty.call(payload, "address")) {
    const address = nonEmptyString(payload.address);
    if (address && address.length > 500) {
      throw new ValidationError("Address must be under 500 characters");
    }
    updates.address = address || null;
  }

  await setDocument(COLLECTIONS.users, id, updates, true);
  const updated = await getDocumentById<StoredUser>(COLLECTIONS.users, id);
  if (!updated) {
    throw new NotFoundError("User not found");
  }

  return normalizeUser(updated);
}

export async function deleteUserData(id: string) {
  const existing = await getDocumentById<StoredUser>(COLLECTIONS.users, id);
  if (!existing) {
    throw new NotFoundError("User not found");
  }

  await deleteDocument(COLLECTIONS.users, id);
  return { success: true };
}

export async function getSettingsData(): Promise<Settings> {
  const settings = await ensureSettingsDocument();
  return {
    loan_period_days: settings.loan_period_days,
    max_books_per_user: settings.max_books_per_user,
    grace_period_days: settings.grace_period_days,
    daily_fine_rate: settings.daily_fine_rate,
    max_fine_cap: settings.max_fine_cap,
    block_on_unpaid_fines: settings.block_on_unpaid_fines,
    fine_threshold: settings.fine_threshold,
    send_notifications: settings.send_notifications,
    notification_days_before_due: settings.notification_days_before_due,
  };
}

export async function updateSettingsData(payload: Record<string, unknown>) {
  const existing = await ensureSettingsDocument();

  const parsedLoanPeriod = toFiniteInt(payload.loan_period_days);
  const parsedMaxBooks = toFiniteInt(payload.max_books_per_user);
  const parsedGraceDays = toFiniteInt(payload.grace_period_days);
  const parsedDailyFineRate = toFiniteNumber(payload.daily_fine_rate);
  const parsedMaxFineCap = toFiniteNumber(payload.max_fine_cap);
  const parsedFineThreshold = toFiniteNumber(payload.fine_threshold);
  const parsedNotifyDays = toFiniteInt(payload.notification_days_before_due);

  if (parsedLoanPeriod !== null && parsedLoanPeriod < 1) {
    throw new ValidationError("loan_period_days must be at least 1");
  }
  if (parsedMaxBooks !== null && parsedMaxBooks < 1) {
    throw new ValidationError("max_books_per_user must be at least 1");
  }
  if (parsedGraceDays !== null && parsedGraceDays < 0) {
    throw new ValidationError("grace_period_days cannot be negative");
  }
  if (parsedDailyFineRate !== null && parsedDailyFineRate <= 0) {
    throw new ValidationError("daily_fine_rate must be greater than 0");
  }
  if (parsedMaxFineCap !== null && parsedMaxFineCap <= 0) {
    throw new ValidationError("max_fine_cap must be greater than 0");
  }
  if (parsedFineThreshold !== null && parsedFineThreshold < 0) {
    throw new ValidationError("fine_threshold cannot be negative");
  }
  if (parsedNotifyDays !== null && parsedNotifyDays < 0) {
    throw new ValidationError(
      "notification_days_before_due cannot be negative",
    );
  }

  const merged: Settings = {
    loan_period_days: parsedLoanPeriod ?? existing.loan_period_days,
    max_books_per_user: parsedMaxBooks ?? existing.max_books_per_user,
    grace_period_days: parsedGraceDays ?? existing.grace_period_days,
    daily_fine_rate: parsedDailyFineRate ?? existing.daily_fine_rate,
    max_fine_cap: parsedMaxFineCap ?? existing.max_fine_cap,
    block_on_unpaid_fines:
      typeof payload.block_on_unpaid_fines === "boolean"
        ? payload.block_on_unpaid_fines
        : existing.block_on_unpaid_fines,
    fine_threshold: parsedFineThreshold ?? existing.fine_threshold,
    send_notifications:
      typeof payload.send_notifications === "boolean"
        ? payload.send_notifications
        : existing.send_notifications,
    notification_days_before_due:
      parsedNotifyDays ?? existing.notification_days_before_due,
  };

  if (merged.max_fine_cap < merged.daily_fine_rate) {
    throw new ValidationError(
      "max_fine_cap must be greater than or equal to daily_fine_rate",
    );
  }

  await setDocument(
    COLLECTIONS.settings,
    SETTINGS_DOC_ID,
    {
      ...merged,
      updated_at: nowIso(),
    },
    true,
  );

  return merged;
}

export async function listFinesData(options: {
  limit?: number;
  page?: number;
  search?: string | null;
  status?: string | null;
}) {
  await syncOverdueLoanFines();

  const page = Math.max(1, options.page || 1);
  const limit = Math.min(100, Math.max(1, options.limit || 10));
  const { fines, users, loans, books, payments } = await loadFineContext();

  const built = buildFineDetails(fines, users, loans, books, payments)
    .filter((fine) =>
      options.status && ["unpaid", "paid", "waived"].includes(options.status)
        ? fine.status === options.status
        : true,
    )
    .filter((fine) =>
      matchesSearch(
        [
          fine.user_name,
          fine.user_email,
          fine.book_title,
          fine.reason,
          fine.id,
          fine.member_id,
          fine.loan_id,
          fine.payment_handled_by,
          fine.payment_notes,
        ],
        options.search,
      ),
    )
    .sort((left, right) =>
      compareDateDesc(
        left.paid_at || left.created_at || left.fine_date,
        right.paid_at || right.created_at || right.fine_date,
      ),
    );

  const total = built.length;
  const offset = (page - 1) * limit;

  return {
    data: built.slice(offset, offset + limit),
    totalCount: total,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

export async function createFineData(payload: Record<string, unknown>) {
  const memberId = nonEmptyString(payload.member_id);
  if (!memberId) {
    throw new ValidationError("member_id is required");
  }

  const amount = toFiniteNumber(payload.fine_amount);
  if (amount === null || amount < 0) {
    throw new ValidationError("fine_amount must be a valid positive number");
  }

  const id = makeId("f");
  const createdAt = nowIso();

  await setDocument(
    COLLECTIONS.fines,
    id,
    {
      member_id: memberId,
      loan_id: nonEmptyString(payload.loan_id) || null,
      fine_date: normalizeDateOnly(payload.fine_date, todayIso()),
      fine_amount: Number(amount.toFixed(2)),
      status: "unpaid",
      reason: nonEmptyString(payload.reason) || null,
      due_date: nonEmptyString(payload.due_date) || null,
      paid_at: null,
      payment_method: null,
      created_at: createdAt,
      updated_at: createdAt,
    },
    false,
  );

  return getFineData(id);
}

export async function getFineData(id: string) {
  await syncOverdueLoanFines();
  const { fines, users, loans, books, payments } = await loadFineContext();
  const built = buildFineDetails(fines, users, loans, books, payments);
  const fine = built.find((entry) => entry.id === id);
  if (!fine) {
    throw new NotFoundError("Fine not found");
  }
  return fine;
}

export async function updateFineData(
  id: string,
  payload: Record<string, unknown>,
) {
  const hasStatusField = Object.prototype.hasOwnProperty.call(payload, "status");
  const requestedStatus = hasStatusField
    ? normalizeFineStatus(payload.status)
    : null;

  if (
    hasStatusField &&
    typeof payload.status === "string" &&
    !["unpaid", "paid", "waived"].includes(payload.status.trim().toLowerCase())
  ) {
    throw new ValidationError("status must be one of: unpaid, paid, waived");
  }

  const paymentMethod = nonEmptyString(payload.payment_method);
  if (paymentMethod && paymentMethod.toLowerCase() !== "physical") {
    throw new ValidationError("Only physical fine payments are supported");
  }

  const fineAmount =
    payload.fine_amount === undefined ? null : toFiniteNumber(payload.fine_amount);
  if (fineAmount !== null && fineAmount < 0) {
    throw new ValidationError("fine_amount must be a valid positive number");
  }

  const paymentAmount =
    payload.payment_amount === undefined
      ? null
      : toFiniteNumber(payload.payment_amount);
  if (paymentAmount !== null && paymentAmount < 0) {
    throw new ValidationError("payment_amount must be a valid positive number");
  }

  const fineDate = nonEmptyString(payload.fine_date);
  const dueDate = nonEmptyString(payload.due_date);
  const reason = nonEmptyString(payload.reason);
  const requestedPaidAt = nonEmptyString(payload.paid_at);
  if (requestedPaidAt && Number.isNaN(Date.parse(requestedPaidAt))) {
    throw new ValidationError("paid_at must be a valid date/time");
  }

  const db = firestore();

  if (paymentAmount !== null) {
    const result = await db.runTransaction(async (transaction) => {
      const fineRef = db.collection(COLLECTIONS.fines).doc(id);
      const fineSnapshot = await transaction.get(fineRef);
      if (!fineSnapshot.exists) {
        throw new NotFoundError("Fine not found");
      }

      const currentFine = normalizeFineBase({
        ...(fineSnapshot.data() as StoredFine),
        id: fineSnapshot.id,
      });
      if (currentFine.status === "waived") {
        throw new ValidationError("Cannot accept payments for a waived fine");
      }

      const outstanding = Number(currentFine.fine_amount || 0);
      if (outstanding <= 0) {
        throw new ValidationError("This fine has no remaining balance");
      }

      const appliedAmount = Math.min(paymentAmount, outstanding);
      if (!Number.isFinite(appliedAmount) || appliedAmount <= 0) {
        throw new ValidationError("payment_amount must be greater than 0");
      }

      const remainingAmount = Number(
        Math.max(0, outstanding - appliedAmount).toFixed(2),
      );
      const nextStatus = remainingAmount <= 0 ? "paid" : "unpaid";
      const paymentRecordedAt = requestedPaidAt
        ? normalizeTimestamp(requestedPaidAt)
        : nowIso();
      const paymentId = makeId("fp");

      transaction.set(
        db.collection(COLLECTIONS.finePayments).doc(paymentId),
        {
          id: paymentId,
          fine_id: id,
          member_id: currentFine.member_id,
          payment_date: paymentRecordedAt.slice(0, 10),
          payment_amount: Number(appliedAmount.toFixed(2)),
          payment_method: "physical",
          handled_by: "admin",
          notes: nonEmptyString(payload.notes) || null,
          created_at: paymentRecordedAt,
        },
        { merge: false },
      );

      transaction.set(
        fineRef,
        stripUndefined({
          fine_amount: remainingAmount,
          fine_date: fineDate
            ? normalizeDateOnly(fineDate, currentFine.fine_date)
            : currentFine.fine_date,
          due_date: dueDate
            ? normalizeDateOnly(dueDate, currentFine.due_date || todayIso())
            : currentFine.due_date,
          reason: reason ?? currentFine.reason,
          status: nextStatus,
          paid_at: nextStatus === "paid" ? paymentRecordedAt : null,
          payment_method: "physical",
          updated_at: nowIso(),
        }),
        { merge: true },
      );

      return {
        appliedAmount: Number(appliedAmount.toFixed(2)),
        remainingAmount,
      };
    });

    return {
      data: await getFineData(id),
      payment: result,
    };
  }

  await db.runTransaction(async (transaction) => {
    const fineRef = db.collection(COLLECTIONS.fines).doc(id);
    const fineSnapshot = await transaction.get(fineRef);
    if (!fineSnapshot.exists) {
      throw new NotFoundError("Fine not found");
    }

    const currentFine = normalizeFineBase({
      ...(fineSnapshot.data() as StoredFine),
      id: fineSnapshot.id,
    });
    const nextStatus = requestedStatus ?? currentFine.status;
    const resolvedFineAmount =
      fineAmount ?? (nextStatus === "paid" ? 0 : currentFine.fine_amount);
    const paidAt =
      nextStatus === "paid"
        ? requestedPaidAt
          ? normalizeTimestamp(requestedPaidAt)
          : currentFine.paid_at || nowIso()
        : null;

    transaction.set(
      fineRef,
      stripUndefined({
        fine_amount: Number(Math.max(0, resolvedFineAmount).toFixed(2)),
        fine_date: fineDate
          ? normalizeDateOnly(fineDate, currentFine.fine_date)
          : currentFine.fine_date,
        due_date: dueDate
          ? normalizeDateOnly(dueDate, currentFine.due_date || todayIso())
          : currentFine.due_date,
        reason: reason ?? currentFine.reason,
        status: nextStatus,
        paid_at: paidAt,
        payment_method: nextStatus === "paid" ? "physical" : null,
        updated_at: nowIso(),
      }),
      { merge: true },
    );

    if (nextStatus === "paid" && currentFine.status !== "paid") {
      const paymentId = makeId("fp");
      transaction.set(
        db.collection(COLLECTIONS.finePayments).doc(paymentId),
        {
          id: paymentId,
          fine_id: id,
          member_id: currentFine.member_id,
          payment_date: (paidAt || nowIso()).slice(0, 10),
          payment_amount: Number(currentFine.fine_amount.toFixed(2)),
          payment_method: "physical",
          handled_by: "admin",
          notes: nonEmptyString(payload.notes) || null,
          created_at: paidAt || nowIso(),
        },
        { merge: false },
      );
    }
  });

  return { data: await getFineData(id) };
}

export async function deleteFineData(id: string) {
  const existing = await getDocumentById<StoredFine>(COLLECTIONS.fines, id);
  if (!existing) {
    throw new NotFoundError("Fine not found");
  }

  const payments = await getAllDocuments<StoredFinePayment>(COLLECTIONS.finePayments);
  const relatedPayments = payments.filter((payment) => payment.fine_id === id);

  const batch = firestore().batch();
  for (const payment of relatedPayments) {
    batch.delete(firestore().collection(COLLECTIONS.finePayments).doc(payment.id));
  }
  batch.delete(firestore().collection(COLLECTIONS.fines).doc(id));
  await batch.commit();

  return { success: true, data: normalizeFineBase(existing) };
}

export async function renewLoanData(id: string) {
  await syncOverdueLoanFines();

  const loan = await getDocumentById<StoredLoan>(COLLECTIONS.loans, id);
  if (!loan) {
    throw new NotFoundError("Loan not found");
  }

  const dueField = nonEmptyString(loan.due_date)
    ? "due_date"
    : nonEmptyString(loan.return_date)
      ? "return_date"
      : nonEmptyString(loan.returned_date)
        ? "returned_date"
        : "due_date";
  const currentDueDate = getLoanDueDate(loan);
  const baseDate =
    currentDueDate && currentDueDate > todayIso() ? currentDueDate : todayIso();
  const renewedDueDate = addDays(baseDate, ADMIN_RENEWAL_DAYS);

  await setDocument(
    COLLECTIONS.loans,
    id,
    {
      [dueField]: renewedDueDate,
      updated_at: nowIso(),
    },
    true,
  );

  return {
    data: {
      ...loan,
      [dueField]: renewedDueDate,
    },
    message:
      currentDueDate && diffDays(todayIso(), currentDueDate) > 0
        ? `Loan renewed by admin for ${ADMIN_RENEWAL_DAYS} days. Late renewal fine updated for overdue days before renewal.`
        : `Loan renewed by admin for ${ADMIN_RENEWAL_DAYS} days.`,
  };
}

export async function getDashboardData() {
  await syncOverdueLoanFines();

  const [users, books, loans, fineContext] = await Promise.all([
    getAllDocuments<StoredUser>(COLLECTIONS.users),
    getAllDocuments<StoredBook>(COLLECTIONS.books),
    getAllDocuments<StoredLoan>(COLLECTIONS.loans),
    loadFineContext(),
  ]);

  const normalizedBooks = books.map((book) =>
    normalizeBook(book, new Map<string, Category>()),
  );
  const fineDetails = buildFineDetails(
    fineContext.fines,
    fineContext.users,
    fineContext.loans,
    fineContext.books,
    fineContext.payments,
  );

  const activeUsers = users.length;
  const totalInventory = normalizedBooks.reduce(
    (sum, book) => sum + (book.copies_owned || 0),
    0,
  );
  const pendingFineList = fineDetails.filter((fine) => fine.status === "unpaid");
  const pendingFines = pendingFineList.reduce(
    (sum, fine) => sum + fine.fine_amount,
    0,
  );

  const completedLoans = loans.filter(
    (loan) =>
      nonEmptyString(loan.loan_date) &&
      (nonEmptyString(loan.returned_date) || nonEmptyString(loan.return_date)),
  );
  const avgCheckoutTime =
    completedLoans.length > 0
      ? Number(
          (
            completedLoans.reduce((sum, loan) => {
              const returnedDate =
                nonEmptyString(loan.returned_date) ||
                nonEmptyString(loan.return_date) ||
                todayIso();
              return sum + diffDays(returnedDate, normalizeDateOnly(loan.loan_date));
            }, 0) / completedLoans.length
          ).toFixed(1),
        )
      : 14;

  const topBookMap = new Map<string, number>();
  for (const loan of loans) {
    const bookId = nonEmptyString(loan.book_id);
    if (!bookId) continue;
    topBookMap.set(bookId, (topBookMap.get(bookId) || 0) + 1);
  }

  const topBooks = [...topBookMap.entries()]
    .map(([id, count]) => ({
      id,
      title: normalizedBooks.find((book) => book.id === id)?.title || "Unknown Book",
      count,
    }))
    .sort((left, right) => right.count - left.count)
    .slice(0, 5);

  const recentFines = [...fineDetails]
    .sort((left, right) =>
      compareDateDesc(left.created_at || left.fine_date, right.created_at || right.fine_date),
    )
    .slice(0, 5)
    .map((fine) => ({
      id: fine.id,
      amount: fine.fine_amount,
      reason: fine.reason || "Overdue fine",
      status: fine.status || "unpaid",
      created_at: fine.created_at || nowIso(),
      users: fine.member_id
        ? {
            id: fine.member_id,
            name: fine.user_name || "Unknown User",
          }
        : null,
    }));

  return {
    stats: {
      activeUsers,
      totalInventory,
      pendingFines: Number(pendingFines.toFixed(2)),
      avgCheckoutTime,
      userGrowth: 12,
      inventoryGrowth: 2,
      fineCount: pendingFineList.length,
      checkoutImprovement: 8,
    },
    topBooks,
    recentFines,
  };
}
