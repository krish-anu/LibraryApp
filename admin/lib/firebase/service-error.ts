import { NextResponse } from "next/server";
import { ConflictError, NotFoundError, ValidationError } from "./library-data";

export function handleFirebaseServiceError(
  context: string,
  error: unknown,
  fallbackMessage = "Internal server error",
) {
  console.error(context, error);

  if (error instanceof ValidationError) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  if (error instanceof NotFoundError) {
    return NextResponse.json({ error: error.message }, { status: 404 });
  }
  if (error instanceof ConflictError) {
    return NextResponse.json({ error: error.message }, { status: 409 });
  }

  return NextResponse.json({ error: fallbackMessage }, { status: 500 });
}
