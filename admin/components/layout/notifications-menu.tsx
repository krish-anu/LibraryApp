"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { Bell } from "lucide-react";
import type { LibraryNotification } from "@/lib/types";

function formatDate(value?: string) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString();
}

export function NotificationsMenu() {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [notifications, setNotifications] = useState<LibraryNotification[]>([]);
  const [unread, setUnread] = useState(0);
  const containerRef = useRef<HTMLDivElement | null>(null);

  const hasNotifications = notifications.length > 0;
  const unreadLabel = useMemo(() => {
    if (unread <= 0) return "";
    if (unread > 99) return "99+";
    return String(unread);
  }, [unread]);

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      const response = await fetch("/api/notifications?limit=6", {
        cache: "no-store",
      });
      const json = await response.json().catch(() => ({ data: [], unread: 0 }));
      setNotifications(Array.isArray(json.data) ? json.data : []);
      setUnread(typeof json.unread === "number" ? json.unread : 0);
    } catch (error) {
      console.error("Error loading notifications:", error);
      setNotifications([]);
      setUnread(0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  useEffect(() => {
    function onClickOutside(event: MouseEvent) {
      if (!containerRef.current) return;
      if (!containerRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    }

    document.addEventListener("mousedown", onClickOutside);
    return () => document.removeEventListener("mousedown", onClickOutside);
  }, []);

  const markAsRead = async (id: string) => {
    try {
      await fetch(`/api/notifications/${id}/read`, { method: "POST" });
      setNotifications((current) =>
        current.map((item) =>
          item.id === id
            ? {
                ...item,
                read: true,
                read_at: new Date().toISOString(),
              }
            : item,
        ),
      );
      setUnread((current) => Math.max(0, current - 1));
    } catch (error) {
      console.error("Error marking notification read:", error);
    }
  };

  return (
    <div className="relative" ref={containerRef}>
      <button
        type="button"
        onClick={() => setOpen((current) => !current)}
        className="relative rounded-lg p-2 transition-colors hover:bg-gray-100"
      >
        <Bell className="h-5 w-5 text-gray-600" />
        {unread > 0 ? (
          <span className="absolute -right-0.5 -top-0.5 min-w-5 rounded-full bg-[#1E3A5F] px-1.5 py-0.5 text-center text-[10px] font-semibold text-white">
            {unreadLabel}
          </span>
        ) : null}
      </button>

      {open && (
        <div className="absolute right-0 z-50 mt-2 w-[22rem] overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xl">
          <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3">
            <div>
              <p className="text-sm font-semibold text-gray-900">Notifications</p>
              <p className="text-xs text-gray-500">
                {unread} unread notification{unread == 1 ? "" : "s"}
              </p>
            </div>
            <Link
              href="/notifications"
              onClick={() => setOpen(false)}
              className="text-xs font-medium text-[#1E3A5F]"
            >
              View all
            </Link>
          </div>

          {loading ? (
            <div className="px-4 py-8 text-center text-sm text-gray-500">
              Loading notifications...
            </div>
          ) : !hasNotifications ? (
            <div className="px-4 py-8 text-center text-sm text-gray-500">
              No notifications yet.
            </div>
          ) : (
            <div className="max-h-[28rem] overflow-y-auto">
              {notifications.map((notification) => (
                <button
                  key={notification.id}
                  type="button"
                  onClick={() => {
                    void markAsRead(notification.id);
                    setOpen(false);
                  }}
                  className={`w-full border-b border-gray-100 px-4 py-3 text-left transition-colors hover:bg-gray-50 ${
                    notification.read ? "bg-white" : "bg-[#1E3A5F]/5"
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <div
                      className={`mt-1 h-2.5 w-2.5 rounded-full ${
                        notification.read ? "bg-gray-300" : "bg-[#1E3A5F]"
                      }`}
                    />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold text-gray-900">
                        {notification.title}
                      </p>
                      <p className="mt-1 line-clamp-2 text-sm text-gray-600">
                        {notification.body}
                      </p>
                      <p className="mt-2 text-xs text-gray-400">
                        {formatDate(notification.created_at)}
                      </p>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
