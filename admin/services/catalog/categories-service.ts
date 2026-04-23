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
