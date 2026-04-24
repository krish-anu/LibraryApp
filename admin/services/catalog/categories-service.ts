import { NextRequest, NextResponse } from "next/server";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";
import type { Category } from "@/lib/types";

export async function GET(request: NextRequest) {
  try {
    const data = await libraryApi<Category[]>(request, "/categories");

    return NextResponse.json({ data });
  } catch (error) {
    return handleLibraryApiError("Error fetching categories:", error);
  }
}

export async function POST(request: NextRequest) {
  try {
    const payload = await request.json();
    const data = await libraryApi<Category>(request, "/categories", {
      method: "POST",
      body: JSON.stringify(payload),
    });

    return NextResponse.json({ data }, { status: 201 });
  } catch (error) {
    return handleLibraryApiError("Error creating category:", error);
  }
}
