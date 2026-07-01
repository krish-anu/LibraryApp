"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { StatCard } from "@/components/ui/stat-card";
import { Badge } from "@/components/ui/badge";
import { formatCurrency } from "@/lib/utils";
import { Users, BookOpen, AlertCircle, Clock, TrendingUp } from "lucide-react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

interface DashboardData {
  stats: {
    activeUsers: number;
    totalInventory: number;
    pendingFines: number;
    avgCheckoutTime: number;
    userGrowth: number;
    inventoryGrowth: number;
    fineCount: number;
    checkoutImprovement: number;
  };
  topBooks: Array<{ id: string; title: string; count: number }>;
  borrowedLast7Days: Array<{ date: string; count: number }>;
  recentFines: Array<{
    id: string;
    amount: number;
    reason: string;
    status: string;
    created_at: string;
    users: { id: string; name: string } | null;
  }>;
}

export default function DashboardPage() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const res = await fetch("/api/dashboard");
      const json = await res
        .json()
        .catch(() => ({ error: "Failed to fetch dashboard data" }));
      if (!res.ok) {
        setErrorMessage(json.error || "Failed to fetch dashboard data");
        setData(null);
        return;
      }
      setErrorMessage("");
      setData(json);
    } catch (error) {
      setErrorMessage("Unable to load dashboard data. Check the server and retry.");
      console.warn("Error fetching dashboard:", error);
      setData(null);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#1E3A5F]" />
      </div>
    );
  }

  const chartData =
    data?.topBooks?.map((book, index) => ({
      id: book.id,
      rank: index + 1,
      title: book.title,
      count: book.count,
    })) ?? [];
  const maxBorrowCount = Math.max(...chartData.map((book) => book.count), 1);

  const borrowedTrendData =
    data?.borrowedLast7Days?.map((day) => {
      const [year, month, date] = day.date.split("-").map(Number);
      const label = new Date(year, month - 1, date).toLocaleDateString(
        undefined,
        {
          month: "short",
          day: "numeric",
        },
      );

      return {
        date: day.date,
        label,
        borrowed: day.count,
      };
    }) ?? [];

  return (
    <div>
      <Header
        title="Dashboard"
        subtitle="Welcome back! Here's your library overview."
      />

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        {errorMessage ? (
          <div className="mb-6 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
            {errorMessage}
          </div>
        ) : null}

        {/* Stats Grid */}
        <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4 sm:gap-6">
          <StatCard
            title="Active Users"
            value={(data?.stats?.activeUsers ?? 0).toLocaleString()}
            change={`${data?.stats?.userGrowth ?? 0}% from last month`}
            changeType="positive"
            icon={Users}
            iconColor="bg-blue-100 text-blue-600"
          />
          <StatCard
            title="Total Inventory"
            value={(data?.stats?.totalInventory ?? 0).toLocaleString()}
            change={`+${data?.stats?.inventoryGrowth ?? 0}% new additions`}
            changeType="positive"
            icon={BookOpen}
            iconColor="bg-green-100 text-green-600"
          />
          <StatCard
            title="Pending Fines"
            value={formatCurrency(data?.stats?.pendingFines ?? 0)}
            change={`${data?.stats?.fineCount ?? 0} unpaid fines`}
            changeType="negative"
            icon={AlertCircle}
            iconColor="bg-red-100 text-red-600"
          />
          <StatCard
            title="Avg. Checkout Time"
            value={`${data?.stats?.avgCheckoutTime ?? 0} days`}
            change={`${data?.stats?.checkoutImprovement ?? 0}% faster returns`}
            changeType="positive"
            icon={Clock}
            iconColor="bg-purple-100 text-purple-600"
          />
        </div>

        <div className="grid grid-cols-1 gap-6 xl:grid-cols-2">
          {/* Most Borrowed Books Chart */}
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <div className="mb-6 flex items-center justify-between gap-4">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">
                  Most Borrowed Books
                </h2>
                <p className="mt-1 text-sm text-gray-500">
                  Ranked by total borrow count
                </p>
              </div>
              <div className="rounded-lg bg-blue-50 p-2 text-blue-600">
                <TrendingUp className="w-5 h-5" />
              </div>
            </div>
            <div className="min-h-64 sm:min-h-72">
              {chartData.length > 0 ? (
                <div className="space-y-5">
                  {chartData.map((book) => {
                    const width = `${Math.max(
                      (book.count / maxBorrowCount) * 100,
                      8,
                    )}%`;

                    return (
                      <div key={book.id} className="space-y-2">
                        <div className="flex items-center gap-3">
                          <div
                            className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-sm font-bold ${
                              book.rank === 1
                                ? "bg-[#1E3A5F] text-white"
                                : "bg-blue-50 text-blue-700"
                            }`}
                          >
                            {book.rank}
                          </div>
                          <div className="min-w-0 flex-1">
                            <p className="truncate text-sm font-semibold text-gray-900">
                              {book.title}
                            </p>
                            <p className="text-xs text-gray-500">
                              {book.count.toLocaleString()} borrow
                              {book.count === 1 ? "" : "s"}
                            </p>
                          </div>
                          <div className="rounded-full bg-gray-100 px-3 py-1 text-sm font-semibold text-gray-800">
                            {book.count}
                          </div>
                        </div>
                        <div className="ml-11 h-3 overflow-hidden rounded-full bg-gray-100">
                          <div
                            className="h-full rounded-full bg-gradient-to-r from-[#1E3A5F] to-[#4A90D9] shadow-sm transition-all"
                            style={{ width }}
                          />
                        </div>
                      </div>
                    );
                  })}
                  <div className="ml-11 flex justify-between border-t border-gray-100 pt-3 text-xs text-gray-400">
                    <span>0</span>
                    <span>{maxBorrowCount.toLocaleString()} borrows</span>
                  </div>
                </div>
              ) : (
                <div className="flex h-full items-center justify-center rounded-lg bg-gray-50 text-sm text-gray-500">
                  No borrowing data available
                </div>
              )}
            </div>
          </div>

          {/* Borrowed Books Trend */}
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <div className="mb-6 flex items-center justify-between gap-4">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">
                  Borrowed Books Trend
                </h2>
                <p className="mt-1 text-sm text-gray-500">Last 7 days</p>
              </div>
              <TrendingUp className="w-5 h-5 text-gray-400" />
            </div>
            <div className="h-64 min-h-64 sm:h-72">
              {borrowedTrendData.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart
                    data={borrowedTrendData}
                    margin={{ top: 12, right: 18, bottom: 8, left: 0 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis
                      dataKey="label"
                      tick={{ fontSize: 12 }}
                      tickLine={false}
                    />
                    <YAxis
                      allowDecimals={false}
                      tick={{ fontSize: 12 }}
                      tickLine={false}
                    />
                    <Tooltip
                      labelFormatter={(_, payload) =>
                        payload?.[0]?.payload?.date ?? ""
                      }
                      formatter={(value) => [value, "Borrowed"]}
                    />
                    <Line
                      type="monotone"
                      dataKey="borrowed"
                      stroke="#2563EB"
                      strokeWidth={3}
                      dot={{ r: 4, strokeWidth: 2 }}
                      activeDot={{ r: 6 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              ) : (
                <div className="flex h-full items-center justify-center rounded-lg bg-gray-50 text-sm text-gray-500">
                  No borrowing trend available
                </div>
              )}
            </div>
          </div>

          {/* Recent Fines */}
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <div className="mb-6 flex items-center justify-between gap-4">
              <h2 className="text-lg font-semibold text-gray-900">
                Recent Fines
              </h2>
              <a
                href="/fines"
                className="text-sm text-blue-600 hover:underline"
              >
                View all
              </a>
            </div>
            <div className="space-y-4">
              {data?.recentFines?.length === 0 ? (
                <p className="text-gray-500 text-center py-8">
                  No recent fines
                </p>
              ) : (
                data?.recentFines?.map((fine) => (
                  <div
                    key={fine.id}
                    className="flex flex-col gap-3 rounded-lg bg-gray-50 p-3 sm:flex-row sm:items-center sm:justify-between"
                  >
                    <div>
                      <p className="font-medium text-gray-900">
                        {fine.users?.name || "Unknown User"}
                      </p>
                      <p className="text-sm text-gray-500">{fine.reason}</p>
                    </div>
                    <div className="sm:text-right">
                      <p className="font-semibold text-gray-900">
                        {formatCurrency(fine.amount)}
                      </p>
                      <Badge
                        variant={fine.status === "paid" ? "success" : "warning"}
                      >
                        {fine.status}
                      </Badge>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Inventory Overview */}
        <div className="mt-6 rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            Quick Actions
          </h2>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <a
              href="/books"
              className="flex items-center gap-3 p-4 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
            >
              <BookOpen className="w-5 h-5 text-blue-600" />
              <span className="font-medium text-blue-900">Manage Books</span>
            </a>
            <a
              href="/users"
              className="flex items-center gap-3 p-4 bg-green-50 rounded-lg hover:bg-green-100 transition-colors"
            >
              <Users className="w-5 h-5 text-green-600" />
              <span className="font-medium text-green-900">Manage Users</span>
            </a>
            <a
              href="/fines"
              className="flex items-center gap-3 p-4 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
            >
              <AlertCircle className="w-5 h-5 text-red-600" />
              <span className="font-medium text-red-900">View Fines</span>
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
