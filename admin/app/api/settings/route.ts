import { NextRequest, NextResponse } from "next/server";
import { createAdminSupabaseClient } from "@/lib/supabase/server";

// GET settings
export async function GET() {
  try {
    const supabase = await createAdminSupabaseClient();

    const { data, error } = await supabase
      .from("settings")
      .select("*")
      .single();

    if (error) {
      // Return default settings if none exist
      return NextResponse.json({
        data: {
          loan_period_days: 14,
          max_books_per_user: 5,
          grace_period_days: 2,
          daily_fine_rate: 0.5,
          max_fine_cap: 25.0,
          block_on_unpaid_fines: true,
          fine_threshold: 10.0,
          send_notifications: true,
          notification_days_before_due: 3,
        },
      });
    }

    return NextResponse.json({ data });
  } catch (error) {
    console.error("Error fetching settings:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

// PUT update settings
export async function PUT(request: NextRequest) {
  try {
    const supabase = await createAdminSupabaseClient();
    const body = await request.json();

    // Try to update existing settings
    const { data: existing } = await supabase
      .from("settings")
      .select("id")
      .single();

    let result;
    if (existing) {
      result = await supabase
        .from("settings")
        .update({
          loan_period_days: body.loan_period_days,
          max_books_per_user: body.max_books_per_user,
          grace_period_days: body.grace_period_days,
          daily_fine_rate: body.daily_fine_rate,
          max_fine_cap: body.max_fine_cap,
          block_on_unpaid_fines: body.block_on_unpaid_fines,
          fine_threshold: body.fine_threshold,
          send_notifications: body.send_notifications,
          notification_days_before_due: body.notification_days_before_due,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existing.id)
        .select()
        .single();
    } else {
      result = await supabase
        .from("settings")
        .insert({
          loan_period_days: body.loan_period_days,
          max_books_per_user: body.max_books_per_user,
          grace_period_days: body.grace_period_days,
          daily_fine_rate: body.daily_fine_rate,
          max_fine_cap: body.max_fine_cap,
          block_on_unpaid_fines: body.block_on_unpaid_fines,
          fine_threshold: body.fine_threshold,
          send_notifications: body.send_notifications,
          notification_days_before_due: body.notification_days_before_due,
        })
        .select()
        .single();
    }

    if (result.error) {
      return NextResponse.json(
        { error: result.error.message },
        { status: 400 },
      );
    }

    return NextResponse.json({ data: result.data });
  } catch (error) {
    console.error("Error updating settings:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
