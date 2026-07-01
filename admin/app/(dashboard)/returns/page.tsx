"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Header } from "@/components/layout/header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Modal } from "@/components/ui/modal";
import { formatDate } from "@/lib/utils";
import {
  BookOpen,
  CheckCircle2,
  Mail,
  Phone,
  RotateCcw,
  Search,
  User,
} from "lucide-react";

interface ReturnLoan {
  id: string;
  book_id: string;
  member_id: string;
  loan_date: string;
  returned_date?: string | null;
  status: string;
  returned_by?: string | null;
  book: {
    id: string;
    title: string;
    author?: string | null;
    copies_owned: number;
    image?: string | null;
  };
  member: {
    id: string;
    member_id?: string | null;
    name: string;
    email?: string | null;
    phone?: string | null;
  };
}

export default function ReturnsPage() {
  const [loans, setLoans] = useState<ReturnLoan[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [returningId, setReturningId] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState("");
  const [selectedLoan, setSelectedLoan] = useState<ReturnLoan | null>(null);
  const [returnedBy, setReturnedBy] = useState("");
  const [returnedByError, setReturnedByError] = useState("");

  const fetchReturns = useCallback(async () => {
    try {
      setLoading(true);
      const res = await fetch("/api/returns");
      const json = await res
        .json()
        .catch(() => ({ error: "Failed to fetch borrowed books" }));

      if (!res.ok) {
        setErrorMessage(json.error || "Failed to fetch borrowed books");
        setLoans([]);
        return;
      }

      setErrorMessage("");
      setLoans(json.data || []);
    } catch (error) {
      console.error("Error fetching borrowed books:", error);
      setErrorMessage("Unable to load borrowed books. Check the server and retry.");
      setLoans([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchReturns();
  }, [fetchReturns]);

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
      ];
      return values.some((value) => value?.toLowerCase().includes(query));
    });
  }, [loans, searchQuery]);

  const openReturnModal = (loan: ReturnLoan) => {
    setSelectedLoan(loan);
    setReturnedBy(loan.member.name);
    setReturnedByError("");
    setErrorMessage("");
  };

  const closeReturnModal = () => {
    if (returningId) return;
    setSelectedLoan(null);
    setReturnedBy("");
    setReturnedByError("");
  };

  const handleReturn = async () => {
    if (!selectedLoan) return;

    const cleanReturnedBy = returnedBy.trim();
    if (!cleanReturnedBy) {
      setReturnedByError("Enter who returned this book.");
      return;
    }

    try {
      setReturningId(selectedLoan.id);
      setSuccessMessage("");
      const res = await fetch(`/api/returns/${selectedLoan.id}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ returned_by: cleanReturnedBy }),
      });
      const json = await res
        .json()
        .catch(() => ({ error: "Failed to return this book" }));

      if (!res.ok) {
        setErrorMessage(json.error || "Failed to return this book");
        return;
      }

      setErrorMessage("");
      setSuccessMessage(
        `Returned "${selectedLoan.book.title}" by ${cleanReturnedBy} and notified ${selectedLoan.member.name}.`,
      );
      setSelectedLoan(null);
      setReturnedBy("");
      setReturnedByError("");
      await fetchReturns();
    } catch (error) {
      console.error("Error returning book:", error);
      setErrorMessage("Unable to return this book. Check the server and retry.");
    } finally {
      setReturningId(null);
    }
  };

  return (
    <div>
      <Header
        title="Book Returns"
        subtitle="Record returned books and notify members"
      />

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        {errorMessage ? (
          <div className="mb-6 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
            {errorMessage}
          </div>
        ) : null}

        {successMessage ? (
          <div className="mb-6 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-900">
            {successMessage}
          </div>
        ) : null}

        <div className="mb-6 rounded-xl border border-gray-100 bg-white p-4 shadow-sm">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div className="relative min-w-0 flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search by book, member, email, or phone..."
                value={searchQuery}
                onChange={(event) => setSearchQuery(event.target.value)}
                className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="flex items-center gap-3 text-sm text-gray-600">
              <Badge variant="info">{filteredLoans.length} active loans</Badge>
              <Button
                type="button"
                variant="secondary"
                onClick={fetchReturns}
                disabled={loading}
              >
                <RotateCcw className="mr-2 h-4 w-4" />
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
              <CheckCircle2 className="mx-auto mb-4 h-12 w-12 text-gray-300" />
              <p>No active borrowed books found</p>
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
                        <p className="font-medium text-gray-900">{loan.book.title}</p>
                        <p className="truncate text-sm text-gray-500">
                          {loan.book.author || "Unknown author"}
                        </p>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 gap-3 text-sm text-gray-600">
                      <div>
                        <p className="text-xs font-medium uppercase text-gray-400">Member</p>
                        <p className="font-medium text-gray-900">{loan.member.name}</p>
                        <p>{loan.member.member_id || loan.member.id}</p>
                      </div>
                      <div>
                        <p className="text-xs font-medium uppercase text-gray-400">Borrowed</p>
                        <p>{formatDate(loan.loan_date)}</p>
                      </div>
                      <div>
                        <p className="text-xs font-medium uppercase text-gray-400">Due</p>
                        <p>{loan.returned_date ? formatDate(loan.returned_date) : "-"}</p>
                      </div>
                    </div>

                    <Button
                      type="button"
                      className="w-full"
                      isLoading={returningId === loan.id}
                      onClick={() => openReturnModal(loan)}
                    >
                      <CheckCircle2 className="mr-2 h-4 w-4" />
                      Mark Returned
                    </Button>
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
                        Phone
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Borrowed
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        Due
                      </th>
                      <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                        Action
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
                              <p className="font-medium text-gray-900">{loan.book.title}</p>
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
                              <p className="font-medium text-gray-900">{loan.member.name}</p>
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
                          {loan.returned_date ? formatDate(loan.returned_date) : "-"}
                        </td>
                        <td className="px-6 py-4 text-right">
                          <Button
                            type="button"
                            size="sm"
                            isLoading={returningId === loan.id}
                            onClick={() => openReturnModal(loan)}
                          >
                            <CheckCircle2 className="mr-2 h-4 w-4" />
                            Mark Returned
                          </Button>
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

      <Modal
        isOpen={selectedLoan !== null}
        onClose={closeReturnModal}
        title="Confirm Book Return"
        size="lg"
      >
        {selectedLoan ? (
          <div className="space-y-6">
            <div className="rounded-lg border border-gray-100 bg-gray-50 p-4">
              <div className="flex items-start gap-3">
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-blue-100 text-blue-700">
                  <BookOpen className="h-6 w-6" />
                </div>
                <div className="min-w-0">
                  <p className="text-base font-semibold text-gray-900">
                    {selectedLoan.book.title}
                  </p>
                  <p className="text-sm text-gray-600">
                    {selectedLoan.book.author || "Unknown author"}
                  </p>
                  <p className="mt-1 text-xs text-gray-500">
                    Book ID: {selectedLoan.book.id}
                  </p>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <p className="text-xs font-medium uppercase text-gray-400">
                  Borrower
                </p>
                <p className="mt-1 font-medium text-gray-900">
                  {selectedLoan.member.name}
                </p>
                <p className="text-sm text-gray-500">
                  {selectedLoan.member.member_id || selectedLoan.member.id}
                </p>
              </div>
              <div>
                <p className="text-xs font-medium uppercase text-gray-400">
                  Contact
                </p>
                <p className="mt-1 text-sm text-gray-700">
                  {selectedLoan.member.phone || "No phone"}
                </p>
                <p className="text-sm text-gray-500">
                  {selectedLoan.member.email || "No email"}
                </p>
              </div>
              <div>
                <p className="text-xs font-medium uppercase text-gray-400">
                  Borrowed Date
                </p>
                <p className="mt-1 text-sm text-gray-700">
                  {formatDate(selectedLoan.loan_date)}
                </p>
              </div>
              <div>
                <p className="text-xs font-medium uppercase text-gray-400">
                  Due Date
                </p>
                <p className="mt-1 text-sm text-gray-700">
                  {selectedLoan.returned_date
                    ? formatDate(selectedLoan.returned_date)
                    : "-"}
                </p>
              </div>
            </div>

            <Input
              label="Returned by"
              value={returnedBy}
              onChange={(event) => {
                setReturnedBy(event.target.value);
                setReturnedByError("");
              }}
              placeholder="Name of the person who returned the book"
              error={returnedByError}
            />

            <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
              <Button
                type="button"
                variant="secondary"
                onClick={closeReturnModal}
                disabled={Boolean(returningId)}
              >
                Cancel
              </Button>
              <Button
                type="button"
                isLoading={returningId === selectedLoan.id}
                onClick={handleReturn}
              >
                <CheckCircle2 className="mr-2 h-4 w-4" />
                Confirm Return
              </Button>
            </div>
          </div>
        ) : null}
      </Modal>
    </div>
  );
}
