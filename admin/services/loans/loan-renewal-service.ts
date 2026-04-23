import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { renewLoanData } from "@/lib/firebase/library-data";
import { handleFirebaseServiceError } from "@/lib/firebase/service-error";

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await verifyAdmin(_request);
  if (auth.error) return auth.error;

  try {
    const { id } = await params;
    return NextResponse.json(await renewLoanData(id));
  } catch (error) {
    return handleFirebaseServiceError("Error renewing loan:", error);
  }
}
