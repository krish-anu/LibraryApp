import { NextResponse } from "next/server";
import { ConflictError, NotFoundError, ValidationError } from "./library-data";

type FirebaseLikeError = Error & {
  code?: number | string;
  details?: string;
  reason?: string;
  errorInfoMetadata?: {
    activationUrl?: string;
    service?: string;
  };
};

function firebaseErrorMessage(error: unknown): string | null {
  if (!(error instanceof Error)) {
    return null;
  }

  const firebaseError = error as FirebaseLikeError;
  const reason = firebaseError.reason || "";
  const service = firebaseError.errorInfoMetadata?.service || "";
  const activationUrl = firebaseError.errorInfoMetadata?.activationUrl;
  const message = `${error.message} ${firebaseError.details || ""}`;

  if (
    reason === "SERVICE_DISABLED" ||
    (service === "firestore.googleapis.com" && message.includes("disabled")) ||
    (message.includes("firestore.googleapis.com") && message.includes("disabled"))
  ) {
    return [
      "Cloud Firestore is disabled for this Firebase project.",
      "Enable the Firestore API in Google Cloud, then retry.",
      activationUrl ? `Activation URL: ${activationUrl}` : "",
    ]
      .filter(Boolean)
      .join(" ");
  }

  if (
    message.includes("firestore.googleapis.com") &&
    message.includes("Name resolution failed")
  ) {
    return "Unable to reach Cloud Firestore from this runtime. Check network/DNS access and retry.";
  }

  return null;
}

export function handleFirebaseServiceError(
  context: string,
  error: unknown,
  fallbackMessage = "Internal server error",
) {
  const message = firebaseErrorMessage(error);
  if (message) {
    console.warn(context, message);
  } else {
    console.error(context, error);
  }

  if (error instanceof ValidationError) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  if (error instanceof NotFoundError) {
    return NextResponse.json({ error: error.message }, { status: 404 });
  }
  if (error instanceof ConflictError) {
    return NextResponse.json({ error: error.message }, { status: 409 });
  }

  if (message) {
    return NextResponse.json({ error: message }, { status: 503 });
  }

  return NextResponse.json({ error: fallbackMessage }, { status: 500 });
}
