import { NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";

export async function GET() {
  try {
    // Get total users count
    const usersResult = await queryOne<{ count: string }>(
      "SELECT COUNT(*) as count FROM users"
    );
    const activeUsers = parseInt(usersResult?.count || '0');

    // Get total inventory (sum of copies_owned)
    const inventoryResult = await queryOne<{ total: string }>(
      "SELECT COALESCE(SUM(copies_owned), 0) as total FROM books"
    );
    const totalInventory = parseInt(inventoryResult?.total || '0');

    // Get pending fines total
    const finesResult = await queryOne<{ total: string; count: string }>(
      "SELECT COALESCE(SUM(fine_amount), 0) as total, COUNT(*) as count FROM fines"
    );
    const pendingFines = parseFloat(finesResult?.total || '0');
    const fineCount = parseInt(finesResult?.count || '0');

    // Get avg checkout time from completed loans
    const avgResult = await queryOne<{ avg_days: string }>(
      `SELECT ROUND(AVG(returned_date - loan_date), 1) as avg_days 
       FROM loans 
       WHERE returned_date IS NOT NULL`
    );
    const avgCheckoutTime = parseFloat(avgResult?.avg_days || '14');

    // Get most borrowed books
    const topBooks = await query<{ id: string; title: string; count: string }>(
      `SELECT b.id, b.title, COUNT(l.id) as count
       FROM loans l
       JOIN books b ON l.book_id = b.id
       GROUP BY b.id, b.title
       ORDER BY count DESC
       LIMIT 5`
    );

    // Get recent fines
    const recentFines = await query<{ id: string; member_id: string; fine_amount: number; fine_date: string; user_name: string }>(
      `SELECT f.id, f.member_id, f.fine_amount, f.fine_date, u.name as user_name
       FROM fines f
       LEFT JOIN users u ON f.member_id = u.id
       ORDER BY f.fine_date DESC
       LIMIT 5`
    );

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
      topBooks: topBooks.map(b => ({ ...b, count: parseInt(b.count) })),
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

