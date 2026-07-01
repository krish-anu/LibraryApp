"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Header } from "@/components/layout/header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { formatDate } from "@/lib/utils";
import {
  BookOpen,
  CheckCircle2,
  Clock,
  History,
  Mail,
  Phone,
  Search,
  User,
} from "lucide-react";

type HistoryMode = "all" | "returned";

interface HistoryLoan {
  id: string;
  book_id: string;
  member_id: string;
  loan_date: string;
  returned_date?: string | null;
  status: string;
  returned_at?: string | null;
  returned_by?: string | null;
  book: {
    id: string;
    title: string;
    author?: string | null;
  };
  member: {
    id: string;
    member_id?: string | null;
    name: string;
    email?: string | null;
    phone?: string | null;
  };
}

function statusBadgeVariant(status: string): "success" | "info" {
  return status.toLowerCase() === "returned" ? "success" : "info";
}

export default function LoanHistoryPage() {
  const [mode, setMode] = useState<HistoryMode>("all");
  const [loans, setLoans] = useState<HistoryLoan[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState("");
  const [searchQuery, setSearchQuery] = useState("");

  const fetchHistory = useCallback(async () => {
    try {
      setLoading(true);
      const query = mode === "returned" ? "?status=returned" : "";
      const res = await fetch(`/api/loan-history${query}`);
      const json = await res
        .json()
        .catch(() => ({ error: "Failed to fetch loan history" }));

      if (!res.ok) {
        setErrorMessage(json.error || "Failed to fetch loan history");
        setLoans([]);
        return;
      }

      setErrorMessage("");
      setLoans(json.data || []);
    } catch (error) {
      console.error("Error fetching loan history:", error);
      setErrorMessage("Unable to load loan history. Check the server and retry.");
      setLoans([]);
    } finally {
      setLoading(false);
    }
  }, [mode]);

  useEffect(() => {
    fetchHistory();
  }, [fetchHistory]);

  const filteredLoans = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    if (!query) return loans;

    return loans.filter((loan) => {
      const values = [
        loan.book.title,
        loan.book.author,
        loan.member.name,
        loan.member.email,
        loan.member.phone,
        loan.member.member_id,
        loan.status,
        loan.returned_by,
      ];
      return values.some((value) => value?.toLowerCase().includes(query));
    });
  }, [loans, searchQuery]);

  const returnedCount = loans.filter(
    (loan) => loan.status.toLowerCase() === "returned",
  ).length;

  return (
    <div>
      <Header
        title="Loan History"
        subtitle="Review borrowed and returned book records"
      />

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        {errorMessage ? (
          <div className="mb-6 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
            {errorMessage}
          </div>
        ) : null}

        <div className="mb-6 rounded-xl border border-gray-100 bg-white p-4 shadow-sm">
          <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
            <div className="inline-flex w-full rounded-lg bg-gray-100 p-1 sm:w-auto">
              <button
                type="button"
                onClick={() => setMode("all")}
                className={`flex flex-1 items-center justify-center gap-2 rounded-md px-4 py-2 text-sm font-medium transition-colors sm:flex-none ${
                  mode === "all"
                    ? "bg-white text-[#1E3A5F] shadow-sm"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                <History className="h-4 w-4" />
                Loan History
              </button>
              <button
                type="button"
                onClick={() => setMode("returned")}
                className={`flex flex-1 items-center justify-center gap-2 rounded-md px-4 py-2 text-sm font-medium transition-colors sm:flex-none ${
                  mode === "returned"
                    ? "bg-white text-[#1E3A5F] shadow-sm"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                <CheckCircle2 className="h-4 w-4" />
                Returned History
              </button>
            </div>

            <div className="relative min-w-0 flex-1 xl:max-w-md">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search by book, member, status, or returner..."
                value={searchQuery}
                onChange={(event) => setSearchQuery(event.target.value)}
                className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="flex items-center gap-3">
              <Badge variant="info">{filteredLoans.length} shown</Badge>
              <Badge variant="success">{returnedCount} returned</Badge>
              <Button
                type="button"
                variant="secondary"
                onClick={fetchHistory}
                disabled={loading}
              >
                Refresh
              </Button>
            </div>
          </div>
        </div>

        <div className="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm">
          {loading ? (
            <div className="flex justify-center px-6 py-12">
              <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-[#1E3A5F]" />
            </div>
          ) : filteredLoans.length === 0 ? (
            <div className="px-6 py-14 text-center text-gray-500">
              <Clock className="mx-auto mb-4 h-12 w-12 text-gray-300" />
              <p>No loan history found</p>
            </div>
          ) : (
            <>
              <div className="divide-y divide-gray-200 md:hidden">
                {filteredLoans.map((loan) => (
                  <div key={loan.id} className="space-y-4 p-4">
                    <div className="flex items-start gap-3">
                      <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-blue-50 text-blue-700">
                        <BookOpen className="h-5 w-5" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="font-medium text-gray-900">
                          {loan.book.title}
                        </p>
                        <p className="truncate text-sm text-gray-500">
                          {loan.book.author || "Unknown author"}
                        </p>
                      </div>
                      <Badge variant={statusBadgeVariant(loan.status)}>
                        {loan.status}
                      </Badge>
                    </div>

                    <div className="grid grid-cols-1 gap-3 text-sm text-gray-600 sm:grid-cols-2">
                      <div>
                        <p className="text-xs font-medium uppercase text-gray-400">
                          Member
                        </p>
                        <p className="font-medium text-gray-900">
                          {loan.member.name}
                        </p>
                        <p>{loan.member.member_id || loan.member.id}</p>
                      </div>
                      <div>
                        <p className="text-xs font-medium uppercase text-gray-400">
                          Borrowed
                        </p>
                        <p>{formatDate(loan.loan_date)}</p>
                      </div>
                      <div>
                        <p className="text-xs font-medium uppercase text-gray-400">
                          Due
                        </p>
                        <p>
                          {loan.returned_date
                            ? formatDate(loan.returned_date)
                            : "-"}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs font-medium uppercase text-gray-400">
                          Returned
                        </p>
                        <p>
                          {loan.returned_at ? formatDate(loan.returned_at) : "-"}
                        </p>
                        {loan.returned_by ? <p>By {loan.returned_by}</p> : null}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <div className="hidden overflow-x-auto md:block">
                <table className="w-full">
                  <thead className="border-b border-gray-200 bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Book
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Member
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Contact
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Borrowed
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Due
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Returned
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 bg-white">
                    {filteredLoans.map((loan) => (
                      <tr key={loan.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-50 text-blue-700">
                              <BookOpen className="h-5 w-5" />
                            </div>
                            <div className="min-w-0">
                              <p className="font-medium text-gray-900">
                                {loan.book.title}
                              </p>
                              <p className="truncate text-sm text-gray-500">
                                {loan.book.author || "Unknown author"}
                              </p>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2">
                            <User className="h-4 w-4 text-gray-400" />
                            <div>
                              <p className="font-medium text-gray-900">
                                {loan.member.name}
                              </p>
                              <p className="text-sm text-gray-500">
                                {loan.member.member_id || loan.member.id}
                              </p>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              <Phone className="h-4 w-4 text-gray-400" />
                              <span>{loan.member.phone || "-"}</span>
                            </div>
                            <div className="flex items-center gap-2">
                              <Mail className="h-4 w-4 text-gray-400" />
                              <span>{loan.member.email || "-"}</span>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          {formatDate(loan.loan_date)}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          {loan.returned_date
                            ? formatDate(loan.returned_date)
                            : "-"}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          <p>
                            {loan.returned_at
                              ? formatDate(loan.returned_at)
                              : "-"}
                          </p>
                          {loan.returned_by ? (
                            <p className="text-xs text-gray-500">
                              By {loan.returned_by}
                            </p>
                          ) : null}
                        </td>
                        <td className="px-6 py-4">
                          <Badge variant={statusBadgeVariant(loan.status)}>
                            {loan.status}
                          </Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
