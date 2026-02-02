import { NextRequest, NextResponse } from "next/server";

// Default settings - stored in memory for now
// In production, you may want to create a settings table
const defaultSettings = {
  loan_period_days: 14,
  max_books_per_user: 5,
  grace_period_days: 2,
  daily_fine_rate: 0.5,
  max_fine_cap: 25.0,
  block_on_unpaid_fines: true,
  fine_threshold: 10.0,
  send_notifications: true,
  notification_days_before_due: 3,
};

let currentSettings = { ...defaultSettings };

// GET settings
export async function GET() {
  try {
    return NextResponse.json({ data: currentSettings });
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
    const body = await request.json();

    // Update current settings
    currentSettings = {
      ...currentSettings,
      ...body,
    };

    return NextResponse.json({ data: currentSettings });
  } catch (error) {
    console.error("Error updating settings:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
