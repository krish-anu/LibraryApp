import { NextRequest, NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";
import { Settings } from "@/lib/types";

const DEFAULT_SETTINGS: Settings = {
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

interface SettingsRow extends Settings {
  id: string;
}

async function ensureSettingsTableAndRow() {
  await query(
    `CREATE TABLE IF NOT EXISTS settings (
      id TEXT PRIMARY KEY,
      loan_period_days INTEGER NOT NULL DEFAULT 14,
      max_books_per_user INTEGER NOT NULL DEFAULT 5,
      grace_period_days INTEGER NOT NULL DEFAULT 2,
      daily_fine_rate NUMERIC(10, 2) NOT NULL DEFAULT 0.50,
      max_fine_cap NUMERIC(10, 2) NOT NULL DEFAULT 25.00,
      block_on_unpaid_fines BOOLEAN NOT NULL DEFAULT true,
      fine_threshold NUMERIC(10, 2) NOT NULL DEFAULT 10.00,
      send_notifications BOOLEAN NOT NULL DEFAULT true,
      notification_days_before_due INTEGER NOT NULL DEFAULT 3,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    )`,
  );

  await query(
    `INSERT INTO settings (
      id,
      loan_period_days,
      max_books_per_user,
      grace_period_days,
      daily_fine_rate,
      max_fine_cap,
      block_on_unpaid_fines,
      fine_threshold,
      send_notifications,
      notification_days_before_due,
      created_at,
      updated_at
    )
    SELECT
      '00000000-0000-0000-0000-000000000001',
      $1, $2, $3, $4, $5, $6, $7, $8, $9,
      NOW(),
      NOW()
    WHERE NOT EXISTS (SELECT 1 FROM settings)`,
    [
      DEFAULT_SETTINGS.loan_period_days,
      DEFAULT_SETTINGS.max_books_per_user,
      DEFAULT_SETTINGS.grace_period_days,
      DEFAULT_SETTINGS.daily_fine_rate,
      DEFAULT_SETTINGS.max_fine_cap,
      DEFAULT_SETTINGS.block_on_unpaid_fines,
      DEFAULT_SETTINGS.fine_threshold,
      DEFAULT_SETTINGS.send_notifications,
      DEFAULT_SETTINGS.notification_days_before_due,
    ],
  );
}

async function getSettingsRow(): Promise<SettingsRow> {
  await ensureSettingsTableAndRow();

  const row = await queryOne<SettingsRow>(
    `SELECT
      id,
      loan_period_days,
      max_books_per_user,
      grace_period_days,
      daily_fine_rate::float8 as daily_fine_rate,
      max_fine_cap::float8 as max_fine_cap,
      block_on_unpaid_fines,
      fine_threshold::float8 as fine_threshold,
      send_notifications,
      notification_days_before_due
    FROM settings
    ORDER BY created_at ASC
    LIMIT 1`,
  );

  if (!row) {
    throw new Error("Failed to load settings row");
  }

  return row;
}

// GET settings
export async function GET() {
  try {
    const row = await getSettingsRow();
    return NextResponse.json({
      data: {
        loan_period_days: row.loan_period_days,
        max_books_per_user: row.max_books_per_user,
        grace_period_days: row.grace_period_days,
        daily_fine_rate: row.daily_fine_rate,
        max_fine_cap: row.max_fine_cap,
        block_on_unpaid_fines: row.block_on_unpaid_fines,
        fine_threshold: row.fine_threshold,
        send_notifications: row.send_notifications,
        notification_days_before_due: row.notification_days_before_due,
      } satisfies Settings,
    });
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
    const body = (await request.json()) as Partial<Settings>;
    const existing = await getSettingsRow();

    const merged: Settings = {
      loan_period_days:
        body.loan_period_days ?? existing.loan_period_days ?? 14,
      max_books_per_user:
        body.max_books_per_user ?? existing.max_books_per_user ?? 5,
      grace_period_days:
        body.grace_period_days ?? existing.grace_period_days ?? 2,
      daily_fine_rate: body.daily_fine_rate ?? existing.daily_fine_rate ?? 0.5,
      max_fine_cap: body.max_fine_cap ?? existing.max_fine_cap ?? 25.0,
      block_on_unpaid_fines:
        body.block_on_unpaid_fines ?? existing.block_on_unpaid_fines ?? true,
      fine_threshold: body.fine_threshold ?? existing.fine_threshold ?? 10.0,
      send_notifications:
        body.send_notifications ?? existing.send_notifications ?? true,
      notification_days_before_due:
        body.notification_days_before_due ??
        existing.notification_days_before_due ??
        3,
    };

    const updated = await queryOne<SettingsRow>(
      `UPDATE settings
      SET
        loan_period_days = $1,
        max_books_per_user = $2,
        grace_period_days = $3,
        daily_fine_rate = $4,
        max_fine_cap = $5,
        block_on_unpaid_fines = $6,
        fine_threshold = $7,
        send_notifications = $8,
        notification_days_before_due = $9,
        updated_at = NOW()
      WHERE id = $10
      RETURNING
        id,
        loan_period_days,
        max_books_per_user,
        grace_period_days,
        daily_fine_rate::float8 as daily_fine_rate,
        max_fine_cap::float8 as max_fine_cap,
        block_on_unpaid_fines,
        fine_threshold::float8 as fine_threshold,
        send_notifications,
        notification_days_before_due`,
      [
        merged.loan_period_days,
        merged.max_books_per_user,
        merged.grace_period_days,
        merged.daily_fine_rate,
        merged.max_fine_cap,
        merged.block_on_unpaid_fines,
        merged.fine_threshold,
        merged.send_notifications,
        merged.notification_days_before_due,
        existing.id,
      ],
    );

    if (!updated) {
      throw new Error("Failed to update settings");
    }

    return NextResponse.json({
      data: {
        loan_period_days: updated.loan_period_days,
        max_books_per_user: updated.max_books_per_user,
        grace_period_days: updated.grace_period_days,
        daily_fine_rate: updated.daily_fine_rate,
        max_fine_cap: updated.max_fine_cap,
        block_on_unpaid_fines: updated.block_on_unpaid_fines,
        fine_threshold: updated.fine_threshold,
        send_notifications: updated.send_notifications,
        notification_days_before_due: updated.notification_days_before_due,
      } satisfies Settings,
    });
  } catch (error) {
    console.error("Error updating settings:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
