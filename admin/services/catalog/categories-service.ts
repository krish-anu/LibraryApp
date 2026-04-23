import { NextResponse } from "next/server";
import { listCategoriesData } from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

export async function GET() {
  try {
    const data = await listCategoriesData();

    return NextResponse.json({ data });
  } catch (error) {
    return handleFirebaseServiceError("Error fetching categories:", error);
  }
}
