import { NextResponse } from "next/server";
import { createAdminSupabaseClient } from "@/lib/supabase/server";

export async function GET() {
  try {
    const supabase = await createAdminSupabaseClient();

    // Get active users count
    const { count: activeUsers } = await supabase
      .from("users")
      .select("*", { count: "exact", head: true })
      .eq("status", "active");

    // Get total inventory
    const { data: inventoryData } = await supabase
      .from("books")
      .select("copies_owned");
    const totalInventory =
      inventoryData?.reduce((sum, book) => sum + (book.copies_owned || 0), 0) ||
      0;

    // Get pending fines
    const { data: finesData } = await supabase
      .from("fines")
      .select("amount")
      .eq("status", "unpaid");
    const pendingFines =
      finesData?.reduce((sum, fine) => sum + fine.amount, 0) || 0;
    const fineCount = finesData?.length || 0;

    // Get active loans for avg checkout time
    const { data: loansData } = await supabase
      .from("loans")
      .select("loan_date, return_date")
      .not("return_date", "is", null);

    let avgCheckoutTime = 14;
    if (loansData && loansData.length > 0) {
      const totalDays = loansData.reduce((sum, loan) => {
        const loanDate = new Date(loan.loan_date);
        const returnDate = new Date(loan.return_date);
        const days = Math.ceil(
          (returnDate.getTime() - loanDate.getTime()) / (1000 * 60 * 60 * 24),
        );
        return sum + days;
      }, 0);
      avgCheckoutTime = Math.round((totalDays / loansData.length) * 10) / 10;
    }

    // Get most viewed/borrowed books
    const { data: mostViewedBooks } = await supabase
      .from("loans")
      .select("book_id, books(id, title)")
      .limit(100);

    const bookCounts: Record<string, { title: string; count: number }> = {};
    mostViewedBooks?.forEach((loan) => {
      const book = loan.books as unknown as {
        id: string;
        title: string;
      } | null;
      if (book) {
        if (!bookCounts[book.id]) {
          bookCounts[book.id] = { title: book.title, count: 0 };
        }
        bookCounts[book.id].count++;
      }
    });

    const topBooks = Object.entries(bookCounts)
      .sort((a, b) => b[1].count - a[1].count)
      .slice(0, 5)
      .map(([id, data]) => ({
        id,
        title: data.title,
        count: data.count,
      }));

    // Get recent fines
    const { data: recentFines } = await supabase
      .from("fines")
      .select(
        `
        *,
        users:user_id (id, name)
      `,
      )
      .order("created_at", { ascending: false })
      .limit(5);

    return NextResponse.json({
      stats: {
        activeUsers: activeUsers || 0,
        totalInventory,
        pendingFines,
        avgCheckoutTime,
        userGrowth: 12, // Placeholder - would need historical data
        inventoryGrowth: 2, // Placeholder
        fineCount,
        checkoutImprovement: 8, // Placeholder
      },
      topBooks,
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
