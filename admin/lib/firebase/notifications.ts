import { getFirebaseAdminApp, getFirebaseFirestore } from "./admin";
import { getMessaging } from "firebase-admin/messaging";
import type { LibraryNotification } from "@/lib/types";

const NOTIFICATIONS_COLLECTION = "notifications";
const DEVICE_TOKENS_COLLECTION = "notificationDevices";

type StoredNotification = LibraryNotification & {
  dedupe_key?: string | null;
  recipient_key: string;
};

type StoredDeviceToken = {
  id: string;
  user_id: string;
  token: string;
  platform?: string;
  created_at?: string;
  updated_at?: string;
  last_seen_at?: string;
};

function nowIso(): string {
  return new Date().toISOString();
}

function recipientKey(recipientType: string, recipientId?: string | null): string {
  const normalizedType = recipientType.trim().toLowerCase();
  const normalizedId = (recipientId || "").trim();
  return `${normalizedType}:${normalizedId || "all"}`;
}

function normalizeData(data?: Record<string, unknown>): Record<string, string> {
  const normalized: Record<string, string> = {};
  if (!data) {
    return normalized;
  }

  for (const [key, value] of Object.entries(data)) {
    if (value === undefined || value === null) continue;
    normalized[key] = String(value);
  }
  return normalized;
}

function sortNotifications<T extends { created_at?: string }>(items: T[]): T[] {
  return [...items].sort((left, right) =>
    (right.created_at || "").localeCompare(left.created_at || ""),
  );
}

async function notificationExists(dedupeKey: string): Promise<StoredNotification | null> {
  const cleaned = dedupeKey.trim();
  if (!cleaned) {
    return null;
  }

  const snapshot = await getFirebaseFirestore()
    .collection(NOTIFICATIONS_COLLECTION)
    .where("dedupe_key", "==", cleaned)
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const doc = snapshot.docs[0];
  return {
    ...(doc.data() as StoredNotification),
    id: doc.id,
  };
}

async function listNotificationsByRecipient(
  recipientType: string,
  recipientId?: string | null,
): Promise<LibraryNotification[]> {
  const snapshot = await getFirebaseFirestore()
    .collection(NOTIFICATIONS_COLLECTION)
    .where("recipient_key", "==", recipientKey(recipientType, recipientId))
    .get();

  return sortNotifications(
    snapshot.docs.map((doc) => ({
      ...(doc.data() as LibraryNotification),
      id: doc.id,
    })),
  );
}

async function listDeviceTokensForUser(userId: string): Promise<string[]> {
  const snapshot = await getFirebaseFirestore()
    .collection(DEVICE_TOKENS_COLLECTION)
    .where("user_id", "==", userId.trim())
    .get();

  return snapshot.docs
    .map((doc) => doc.data() as StoredDeviceToken)
    .map((doc) => (doc.token || "").trim())
    .filter(Boolean);
}

async function sendPushNotificationToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, unknown>,
) {
  const tokens = await listDeviceTokensForUser(userId);
  if (tokens.length === 0) {
    return;
  }

  const messaging = getMessaging(getFirebaseAdminApp());
  const normalizedData = normalizeData(data);
  const invalidTokens: string[] = [];

  for (const token of tokens) {
    try {
      await messaging.send({
        token,
        notification: { title, body },
        data: normalizedData,
        android: { priority: "high" },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });
    } catch {
      invalidTokens.push(token);
    }
  }

  if (invalidTokens.length === 0) {
    return;
  }

  const db = getFirebaseFirestore();
  const cleanup = await db
    .collection(DEVICE_TOKENS_COLLECTION)
    .where("user_id", "==", userId.trim())
    .get();

  const batch = db.batch();
  for (const doc of cleanup.docs) {
    const stored = doc.data() as StoredDeviceToken;
    if (invalidTokens.includes((stored.token || "").trim())) {
      batch.delete(doc.ref);
    }
  }
  await batch.commit();
}

async function createNotification(options: {
  recipientType: "user" | "admin";
  recipientId?: string | null;
  title: string;
  body: string;
  category: string;
  entityType?: string | null;
  entityId?: string | null;
  metadata?: Record<string, unknown>;
  dedupeKey?: string | null;
  sendPush?: boolean;
  pushData?: Record<string, unknown>;
}): Promise<LibraryNotification> {
  const dedupeKey = (options.dedupeKey || "").trim();
  if (dedupeKey) {
    const existing = await notificationExists(dedupeKey);
    if (existing) {
      return existing;
    }
  }

  const id = getFirebaseFirestore().collection(NOTIFICATIONS_COLLECTION).doc().id;
  const createdAt = nowIso();
  const notification: StoredNotification = {
    id,
    recipient_type: options.recipientType,
    recipient_id: (options.recipientId || "").trim() || undefined,
    recipient_key: recipientKey(options.recipientType, options.recipientId),
    title: options.title.trim(),
    body: options.body.trim(),
    category: options.category.trim(),
    entity_type: (options.entityType || "").trim() || undefined,
    entity_id: (options.entityId || "").trim() || undefined,
    metadata: options.metadata || {},
    read: false,
    read_at: undefined,
    created_at: createdAt,
    updated_at: createdAt,
    dedupe_key: dedupeKey || undefined,
  };

  await getFirebaseFirestore()
    .collection(NOTIFICATIONS_COLLECTION)
    .doc(id)
    .set(notification);

  if (
    options.sendPush &&
    options.recipientType === "user" &&
    (options.recipientId || "").trim()
  ) {
    await sendPushNotificationToUser(
      (options.recipientId || "").trim(),
      notification.title,
      notification.body,
      {
        notification_id: notification.id,
        category: notification.category,
        entity_type: notification.entity_type || "",
        entity_id: notification.entity_id || "",
        ...(options.pushData || {}),
      },
    );
  }

  return notification;
}

export async function createUserNotification(
  userId: string,
  options: {
    title: string;
    body: string;
    category: string;
    entityType?: string | null;
    entityId?: string | null;
    metadata?: Record<string, unknown>;
    dedupeKey?: string | null;
    sendPush?: boolean;
    pushData?: Record<string, unknown>;
  },
) {
  return createNotification({
    recipientType: "user",
    recipientId: userId,
    title: options.title,
    body: options.body,
    category: options.category,
    entityType: options.entityType,
    entityId: options.entityId,
    metadata: options.metadata,
    dedupeKey: options.dedupeKey,
    sendPush: options.sendPush ?? true,
    pushData: options.pushData,
  });
}

export async function createAdminNotification(options: {
  title: string;
  body: string;
  category: string;
  entityType?: string | null;
  entityId?: string | null;
  metadata?: Record<string, unknown>;
  dedupeKey?: string | null;
}) {
  return createNotification({
    recipientType: "admin",
    title: options.title,
    body: options.body,
    category: options.category,
    entityType: options.entityType,
    entityId: options.entityId,
    metadata: options.metadata,
    dedupeKey: options.dedupeKey,
    sendPush: false,
  });
}

export async function listAdminNotifications(limit = 50): Promise<LibraryNotification[]> {
  const items = await listNotificationsByRecipient("admin");
  return items.slice(0, Math.max(1, Math.min(limit, 100)));
}

export async function adminUnreadNotificationCount(): Promise<number> {
  const items = await listNotificationsByRecipient("admin");
  return items.filter((item) => !item.read).length;
}

export async function markAdminNotificationRead(
  notificationId: string,
): Promise<LibraryNotification> {
  const ref = getFirebaseFirestore()
    .collection(NOTIFICATIONS_COLLECTION)
    .doc(notificationId);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    throw new Error("Notification not found");
  }

  const data = snapshot.data() as StoredNotification;
  if (data.recipient_key !== recipientKey("admin")) {
    throw new Error("Notification not found");
  }

  const updated = {
    read: true,
    read_at: nowIso(),
    updated_at: nowIso(),
  };
  await ref.set(updated, { merge: true });

  return {
    ...data,
    ...updated,
    id: snapshot.id,
  };
}

export async function markAllAdminNotificationsRead(): Promise<number> {
  const items = await listNotificationsByRecipient("admin");
  const unread = items.filter((item) => !item.read);
  if (unread.length === 0) {
    return 0;
  }

  const batch = getFirebaseFirestore().batch();
  const updatedAt = nowIso();
  for (const item of unread) {
    batch.set(
      getFirebaseFirestore().collection(NOTIFICATIONS_COLLECTION).doc(item.id),
      {
        read: true,
        read_at: updatedAt,
        updated_at: updatedAt,
      },
      { merge: true },
    );
  }
  await batch.commit();
  return unread.length;
}
