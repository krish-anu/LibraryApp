"use client";

import { useEffect, useRef, useState } from "react";
import { LogOut, Search, User } from "lucide-react";
import { NotificationsMenu } from "./notifications-menu";
import { useAuth } from "@/lib/auth/auth-context";

interface HeaderProps {
  title: string;
  subtitle?: string;
}

export function Header({ title, subtitle }: HeaderProps) {
  const { user, logout } = useAuth();
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);
  const displayName = user?.name || user?.email || "Admin";
  const initials = displayName
    .split(" ")
    .map((part) => part[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  useEffect(() => {
    const handlePointerDown = (event: PointerEvent) => {
      if (
        profileRef.current &&
        !profileRef.current.contains(event.target as Node)
      ) {
        setIsProfileOpen(false);
      }
    };

    document.addEventListener("pointerdown", handlePointerDown);
    return () => document.removeEventListener("pointerdown", handlePointerDown);
  }, []);

  return (
    <header className="border-b border-gray-200 bg-white px-4 py-4 sm:px-6 lg:px-8">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div className="min-w-0">
          <h1 className="text-xl font-bold text-gray-900 sm:text-2xl">
            {title}
          </h1>
          {subtitle && <p className="text-sm text-gray-500 mt-1">{subtitle}</p>}
        </div>

        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-end">
          <div className="relative w-full sm:max-w-xs">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search..."
              className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div className="flex items-center justify-end gap-2 lg:gap-3">
            <NotificationsMenu />

            <div ref={profileRef} className="relative">
              <button
                type="button"
                onClick={() => setIsProfileOpen((current) => !current)}
                aria-expanded={isProfileOpen}
                aria-label="Open admin profile menu"
                className="flex items-center gap-2 rounded-lg p-2 transition-colors hover:bg-gray-100"
              >
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-[#1E3A5F] text-xs font-semibold text-white">
                  {initials || <User className="h-4 w-4 text-white" />}
                </div>
              </button>

              {isProfileOpen ? (
                <div className="absolute right-0 z-50 mt-2 w-72 rounded-xl border border-gray-100 bg-white p-4 shadow-xl">
                  <div className="flex items-start gap-3">
                    <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-[#1E3A5F] text-sm font-semibold text-white">
                      {initials || <User className="h-5 w-5 text-white" />}
                    </div>
                    <div className="min-w-0">
                      <p className="truncate font-semibold text-gray-900">
                        {displayName}
                      </p>
                      <p className="truncate text-sm text-gray-500">
                        {user?.email || "No email available"}
                      </p>
                      <p className="mt-1 text-xs font-medium uppercase tracking-wide text-blue-600">
                        Administrator
                      </p>
                    </div>
                  </div>

                  <div className="mt-4 rounded-lg bg-gray-50 p-3 text-xs text-gray-500">
                    <p className="font-medium text-gray-700">Admin ID</p>
                    <p className="mt-1 break-all">{user?.sub || "Unknown"}</p>
                  </div>

                  <button
                    type="button"
                    onClick={logout}
                    className="mt-4 flex w-full items-center justify-center gap-2 rounded-lg bg-[#1E3A5F] px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-[#2A4A6F]"
                  >
                    <LogOut className="h-4 w-4" />
                    Logout
                  </button>
                </div>
              ) : null}
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
