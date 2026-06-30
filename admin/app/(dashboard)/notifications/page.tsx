"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import type { LibraryNotification } from "@/lib/types";

function formatDate(value?: string) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString();
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<LibraryNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [markingAll, setMarkingAll] = useState(false);

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      const response = await fetch("/api/notifications", { cache: "no-store" });
      const json = await response.json().catch(() => ({ data: [] }));
      if (!response.ok) {
        throw new Error(json.error || "Failed to load notifications");
      }
      setNotifications(Array.isArray(json.data) ? json.data : []);
    } catch (error) {
      console.error("Error fetching notifications:", error);
      setNotifications([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  const markAsRead = async (id: string) => {
    try {
      const response = await fetch(`/api/notifications/${id}/read`, {
        method: "POST",
      });
      if (!response.ok) throw new Error("Failed to mark notification read");
      setNotifications((current) =>
        current.map((item) =>
          item.id === id
            ? { ...item, read: true, read_at: new Date().toISOString() }
            : item,
        ),
      );
    } catch (error) {
      console.error("Error marking notification read:", error);
    }
  };

  const markAllAsRead = async () => {
    try {
      setMarkingAll(true);
      const response = await fetch("/api/notifications", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "read_all" }),
      });
      if (!response.ok) throw new Error("Failed to mark notifications read");
      setNotifications((current) =>
        current.map((item) => ({
          ...item,
          read: true,
          read_at: new Date().toISOString(),
        })),
      );
    } catch (error) {
      console.error("Error marking all notifications read:", error);
    } finally {
      setMarkingAll(false);
    }
  };

  const unreadCount = notifications.filter((item) => !item.read).length;

  return (
    <div>
      <Header
        title="Notifications"
        subtitle="System activity, member events, reminders, and admin actions"
      />

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        <div className="mb-4 flex items-center justify-between rounded-xl border border-gray-100 bg-white px-5 py-4 shadow-sm">
          <div>
            <p className="text-sm font-medium text-gray-500">Unread</p>
            <p className="text-2xl font-bold text-gray-900">{unreadCount}</p>
          </div>
          <button
            type="button"
            onClick={markAllAsRead}
            disabled={markingAll || unreadCount === 0}
            className="rounded-lg bg-[#1E3A5F] px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-[#274a73] disabled:cursor-not-allowed disabled:opacity-50"
          >
            {markingAll ? "Updating..." : "Mark all as read"}
          </button>
        </div>

        <div className="overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm">
          {loading ? (
            <div className="px-6 py-12 text-center text-sm text-gray-500">
              Loading notifications...
            </div>
          ) : notifications.length === 0 ? (
            <div className="px-6 py-12 text-center text-sm text-gray-500">
              No notifications yet.
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {notifications.map((notification) => (
                <button
                  key={notification.id}
                  type="button"
                  onClick={() => markAsRead(notification.id)}
                  className={`w-full px-6 py-4 text-left transition-colors hover:bg-gray-50 ${
                    notification.read ? "bg-white" : "bg-[#1E3A5F]/5"
                  }`}
                >
                  <div className="flex items-start gap-4">
                    <div
                      className={`mt-1 h-2.5 w-2.5 rounded-full ${
                        notification.read ? "bg-gray-300" : "bg-[#1E3A5F]"
                      }`}
                    />
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                        <div className="min-w-0">
                          <p className="truncate text-base font-semibold text-gray-900">
                            {notification.title}
                          </p>
                          <p className="mt-1 text-sm text-gray-600">
                            {notification.body}
                          </p>
                        </div>
                        <div className="shrink-0 text-xs text-gray-400">
                          {formatDate(notification.created_at)}
                        </div>
                      </div>
                      <div className="mt-3 flex flex-wrap gap-2">
                        <span className="rounded-full bg-gray-100 px-3 py-1 text-xs font-medium text-gray-600">
                          {notification.category.replaceAll("_", " ")}
                        </span>
                        {notification.entity_type ? (
                          <span className="rounded-full bg-[#1E3A5F]/10 px-3 py-1 text-xs font-medium text-[#1E3A5F]">
                            {notification.entity_type}
                          </span>
                        ) : null}
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
