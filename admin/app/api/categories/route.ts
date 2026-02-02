import { NextResponse } from "next/server";
import { query } from "@/lib/db";
import { Category } from "@/lib/types";

export async function GET() {
  try {
    const data = await query<Category>(
      "SELECT * FROM categories ORDER BY name",
    );

    return NextResponse.json({ data });
  } catch (error) {
    console.error("Error fetching categories:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
