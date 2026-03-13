"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard,
  BookOpen,
  Users,
  AlertCircle,
  Settings,
  LogOut,
  Library,
} from "lucide-react";

const navigation = [
  { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { name: "Book Inventory", href: "/books", icon: BookOpen },
  { name: "User Management", href: "/users", icon: Users },
  { name: "Fines & Penalties", href: "/fines", icon: AlertCircle },
  { name: "Settings", href: "/settings", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  const handleLogout = async () => {
    window.location.href = "/api/auth/logout";
  };

  return (
    <>
      <aside className="fixed left-0 top-0 hidden h-full w-64 flex-col bg-[#1E3A5F] text-white lg:flex">
        <div className="border-b border-white/10 p-6">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-white/10 p-2">
              <Library className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-lg font-bold">Library Admin</h1>
              <p className="text-xs text-white/60">Management Portal</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 space-y-1 p-4">
          {navigation.map((item) => {
            const isActive =
              pathname === item.href || pathname.startsWith(item.href + "/");
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-4 py-3 transition-colors",
                  isActive
                    ? "bg-white/20 text-white"
                    : "text-white/70 hover:bg-white/10 hover:text-white",
                )}
              >
                <item.icon className="h-5 w-5" />
                <span className="font-medium">{item.name}</span>
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-white/10 p-4">
          <button
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-white/70 transition-colors hover:bg-white/10 hover:text-white"
          >
            <LogOut className="h-5 w-5" />
            <span className="font-medium">Logout</span>
          </button>
        </div>
      </aside>

      <div className="sticky top-0 z-40 border-b border-[#35557d] bg-[#1E3A5F] text-white shadow-sm lg:hidden">
        <div className="flex items-center justify-between gap-4 px-4 py-4">
          <div className="flex min-w-0 items-center gap-3">
            <div className="rounded-lg bg-white/10 p-2">
              <Library className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <h1 className="truncate text-base font-bold">Library Admin</h1>
              <p className="truncate text-xs text-white/60">
                Management Portal
              </p>
            </div>
          </div>

          <button
            onClick={handleLogout}
            className="inline-flex items-center gap-2 rounded-lg border border-white/15 px-3 py-2 text-sm font-medium text-white/85 transition-colors hover:bg-white/10"
          >
            <LogOut className="h-4 w-4" />
            Logout
          </button>
        </div>

        <nav className="overflow-x-auto px-4 pb-4">
          <div className="flex min-w-max gap-2">
            {navigation.map((item) => {
              const isActive =
                pathname === item.href || pathname.startsWith(item.href + "/");
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn(
                    "inline-flex items-center gap-2 rounded-full border px-3 py-2 text-sm font-medium transition-colors",
                    isActive
                      ? "border-white/30 bg-white text-[#1E3A5F]"
                      : "border-white/15 bg-white/5 text-white/85 hover:bg-white/10",
                  )}
                >
                  <item.icon className="h-4 w-4" />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </div>
        </nav>
      </div>
    </>
  );
}
