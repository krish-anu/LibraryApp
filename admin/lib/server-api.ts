import { NextRequest, NextResponse } from "next/server";

export class LibraryApiError extends Error {
  status: number;
  details: unknown;

  constructor(message: string, status: number, details: unknown) {
    super(message);
    this.name = "LibraryApiError";
    this.status = status;
    this.details = details;
  }
}

function apiBaseUrl() {
  return (
    process.env.LIBRARY_API_BASE_URL ||
    process.env.SERVER_API_URL ||
    "http://127.0.0.1:8000"
  ).replace(/\/+$/, "");
}

async function readResponseBody(response: Response) {
  const contentType = response.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    return response.json().catch(() => null);
  }
  return response.text().catch(() => "");
}

export async function libraryApi<T>(
  request: NextRequest,
  path: string,
  init: RequestInit = {},
): Promise<T> {
  const headers = new Headers(init.headers);
  const accessToken = request.cookies.get("library_session")?.value;

  if (accessToken && !headers.has("Authorization")) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  if (init.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  const response = await fetch(`${apiBaseUrl()}${path}`, {
    ...init,
    headers,
    cache: "no-store",
  });

  if (response.status === 204) {
    return undefined as T;
  }

  const body = await readResponseBody(response);

  if (!response.ok) {
    const message =
      typeof body === "object" && body && "detail" in body
        ? String((body as { detail?: unknown }).detail)
        : `Library API request failed with status ${response.status}`;
    throw new LibraryApiError(message, response.status, body);
  }

  return body as T;
}

export function handleLibraryApiError(context: string, error: unknown) {
  console.error(context, error);

  if (error instanceof LibraryApiError) {
    return NextResponse.json(
      {
        error: error.message,
        details: error.details,
      },
      { status: error.status },
    );
  }

  return NextResponse.json(
    { error: "Unable to reach the library API" },
    { status: 502 },
  );
}
