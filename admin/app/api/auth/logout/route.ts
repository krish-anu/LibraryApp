import { NextResponse } from "next/server";
import { cookies } from "next/headers";

export async function POST() {
  const cookieStore = await cookies();

  cookieStore.delete("admin_token");
  cookieStore.delete("admin_id_token");
  cookieStore.delete("admin_user");

  return NextResponse.json({ success: true });
}
