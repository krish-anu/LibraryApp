import { NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";
import { ensureFineInfrastructure } from "@/lib/fines";

export async function GET() {
  try {
    await ensureFineInfrastructure();

    // Get total users count
    const usersResult = await queryOne<{ count: string }>(
      "SELECT COUNT(*) as count FROM users",
    );
    const activeUsers = parseInt(usersResult?.count || "0");

    // Get total inventory (sum of copies_owned)
    const inventoryResult = await queryOne<{ total: string }>(
      "SELECT COALESCE(SUM(copies_owned), 0) as total FROM books",
    );
    const totalInventory = parseInt(inventoryResult?.total || "0");

    // Get pending fines total
    const finesResult = await queryOne<{ total: string; count: string }>(
      `SELECT
        COALESCE(SUM(fine_amount), 0) as total,
        COUNT(*) as count
       FROM fines
       WHERE LOWER(COALESCE(status, 'unpaid')) = 'unpaid'`,
    );
    const pendingFines = parseFloat(finesResult?.total || "0");
    const fineCount = parseInt(finesResult?.count || "0");

    // Get avg checkout time from completed loans
    const avgResult = await queryOne<{ avg_days: string }>(
      `SELECT ROUND(AVG(returned_date - loan_date), 1) as avg_days 
       FROM loans 
       WHERE returned_date IS NOT NULL`,
    );
    const avgCheckoutTime = parseFloat(avgResult?.avg_days || "14");

    // Get most borrowed books
    const topBooks = await query<{ id: string; title: string; count: string }>(
      `SELECT b.id, b.title, COUNT(l.id) as count
       FROM loans l
       JOIN books b ON l.book_id = b.id
       GROUP BY b.id, b.title
       ORDER BY count DESC
       LIMIT 5`,
    );

    // Get recent fines
    const recentFinesRaw = await query<{
      id: string;
      amount: number;
      reason: string;
      status: string;
      created_at: string;
      user_id: string | null;
      user_name: string;
    }>(
      `SELECT
        f.id,
        f.fine_amount::float8 as amount,
        COALESCE(f.reason, 'Overdue fine') as reason,
        LOWER(COALESCE(f.status, 'unpaid')) as status,
        COALESCE(f.created_at, f.fine_date::timestamp) as created_at,
        u.id as user_id,
        u.name as user_name
       FROM fines f
       LEFT JOIN users u ON f.member_id = u.id
       ORDER BY COALESCE(f.created_at, f.fine_date::timestamp) DESC
       LIMIT 5`,
    );
    const recentFines = recentFinesRaw.map((fine) => ({
      id: fine.id,
      amount: Number(fine.amount || 0),
      reason: fine.reason,
      status: fine.status,
      created_at: fine.created_at,
      users: fine.user_id
        ? { id: fine.user_id, name: fine.user_name || "Unknown User" }
        : null,
    }));

    return NextResponse.json({
      stats: {
        activeUsers,
        totalInventory,
        pendingFines,
        avgCheckoutTime: avgCheckoutTime || 14,
        userGrowth: 12, // Placeholder
        inventoryGrowth: 2, // Placeholder
        fineCount,
        checkoutImprovement: 8, // Placeholder
      },
      topBooks: topBooks.map((b) => ({ ...b, count: parseInt(b.count) })),
      recentFines,
    });
  } catch (error) {
    console.error("Error fetching dashboard stats:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
