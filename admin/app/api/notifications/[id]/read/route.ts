import { NextRequest } from "next/server";
import { POST as handleRead } from "@/services/notifications/notification-read-service";

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  const { id } = await context.params;
  return handleRead(request, id);
}
