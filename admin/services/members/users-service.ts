import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";

function collectionPath(request: NextRequest) {
  const params = new URLSearchParams();
  for (const key of ["page", "limit", "search", "status"]) {
    const value = request.nextUrl.searchParams.get(key);
    if (value) params.set(key, value);
  }
  const query = params.toString();
  return query ? `/users?${query}` : "/users";
}

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    return NextResponse.json(await libraryApi(request, collectionPath(request)));
  } catch (error) {
    return handleLibraryApiError("Error fetching users:", error);
  }
}

export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const data = await libraryApi(request, "/users", {
      method: "POST",
      body: JSON.stringify(await request.json()),
    });
    return NextResponse.json({ data }, { status: 201 });
  } catch (error) {
    return handleLibraryApiError("Error creating user:", error);
  }
}
