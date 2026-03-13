"use client";

import { useCallback, useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Modal } from "@/components/ui/modal";
import { formatCurrency, formatDate } from "@/lib/utils";
import { Fine } from "@/lib/types";
import {
  Plus,
  Search,
  ChevronLeft,
  ChevronRight,
  AlertCircle,
  Wallet,
  RefreshCw,
  X,
} from "lucide-react";

interface FineWithRelations extends Fine {
  user_name?: string;
  user_email?: string;
  book_title?: string;
  payment_date?: string;
  payment_amount?: number;
  payment_handled_by?: string;
  payment_notes?: string;
  total_paid?: number;
  payment_count?: number;
  total_fine_amount?: number;
  user_total_due?: number;
}

interface FineFormData {
  member_id: string;
  loan_id: string;
  fine_amount: number;
  fine_date: string;
  due_date: string;
  reason: string;
}

const initialFormData: FineFormData = {
  member_id: "",
  loan_id: "",
  fine_amount: 0,
  fine_date: new Date().toISOString().split("T")[0],
  due_date: "",
  reason: "",
};

export default function FinesPage() {
  const [fines, setFines] = useState<FineWithRelations[]>([]);
  const [users, setUsers] = useState<{ id: string; name: string }[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const limit = 10;

  // Filters
  const [searchQuery, setSearchQuery] = useState("");

  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState<FineFormData>(initialFormData);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isManageModalOpen, setIsManageModalOpen] = useState(false);
  const [selectedFine, setSelectedFine] = useState<FineWithRelations | null>(
    null,
  );
  const [paymentInput, setPaymentInput] = useState("");
  const [paymentNotes, setPaymentNotes] = useState("");
  const [isRecordingPayment, setIsRecordingPayment] = useState(false);
  const [isRenewingLoan, setIsRenewingLoan] = useState(false);

  // Tab state
  const [activeTab, setActiveTab] = useState<"all" | "unpaid" | "paid">("all");

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const usersRes = await fetch("/api/users?limit=100");
      const usersJson = await usersRes.json();
      setUsers(usersJson.data || []);
    } catch (error) {
      console.error("Error fetching users:", error);
    }
  };

  const fetchFines = useCallback(async () => {
    try {
      setLoading(true);
      setErrorMessage(null);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: limit.toString(),
      });
      if (searchQuery) params.append("search", searchQuery);
      if (activeTab !== "all") params.append("status", activeTab);

      const res = await fetch(`/api/fines?${params}`);
      if (!res.ok) {
        const error = await res
          .json()
          .catch(() => ({ error: "Failed to fetch fines" }));
        throw new Error(error.error || "Failed to fetch fines");
      }
      const json = await res.json();
      setFines(json.data || []);
      setTotalCount(json.totalCount || json.pagination?.total || 0);
    } catch (error) {
      console.error("Error fetching fines:", error);
      setFines([]);
      setTotalCount(0);
      setErrorMessage(
        error instanceof Error ? error.message : "Failed to fetch fines",
      );
    } finally {
      setLoading(false);
    }
  }, [activeTab, limit, page, searchQuery]);

  useEffect(() => {
    fetchFines();
  }, [fetchFines]);

  const handleOpenModal = () => {
    setFormData(initialFormData);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setFormData(initialFormData);
  };

  const handleOpenManageModal = (fine: FineWithRelations) => {
    setSelectedFine(fine);
    setPaymentInput(Number(fine.fine_amount || 0).toFixed(2));
    setPaymentNotes("");
    setIsManageModalOpen(true);
  };

  const handleCloseManageModal = () => {
    setIsManageModalOpen(false);
    setSelectedFine(null);
    setPaymentInput("");
    setPaymentNotes("");
    setIsRecordingPayment(false);
    setIsRenewingLoan(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      const res = await fetch("/api/fines", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      if (res.ok) {
        handleCloseModal();
        fetchFines();
      } else {
        const error = await res.json();
        alert(error.error || "Failed to create fine");
      }
    } catch (error) {
      console.error("Error creating fine:", error);
      alert("Failed to create fine");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRecordPhysicalPayment = async () => {
    if (!selectedFine) return;

    const amount = Number(paymentInput);
    if (!Number.isFinite(amount) || amount <= 0) {
      alert("Enter a valid payment amount greater than 0");
      return;
    }

    try {
      setIsRecordingPayment(true);
      const res = await fetch(`/api/fines/${selectedFine.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          payment_amount: amount,
          payment_method: "physical",
          notes: paymentNotes,
        }),
      });

      const json = await res
        .json()
        .catch(() => ({ error: "Failed to record payment" }));
      if (!res.ok) {
        alert(json.error || "Failed to record payment");
        return;
      }

      const appliedAmount = Number(json?.payment?.appliedAmount ?? amount);
      const remaining = Number(
        json?.payment?.remainingAmount ?? json?.data?.fine_amount ?? 0,
      );
      const sanitizedRemaining = Number.isFinite(remaining)
        ? Math.max(0, remaining)
        : 0;
      const sanitizedAppliedAmount = Number.isFinite(appliedAmount)
        ? Math.max(0, appliedAmount)
        : 0;

      await fetchFines();

      if (remaining > 0) {
        setSelectedFine((current) => {
          if (!current) return current;
          const previousTotalPaid = toAmount(current.total_paid ?? current.payment_amount);
          return {
            ...current,
            fine_amount: sanitizedRemaining,
            total_paid: previousTotalPaid + sanitizedAppliedAmount,
            payment_amount: sanitizedAppliedAmount,
            payment_date: new Date().toISOString().slice(0, 10),
            payment_handled_by: "admin",
            payment_notes: paymentNotes || undefined,
            status: "unpaid",
          };
        });
        setPaymentInput(sanitizedRemaining.toFixed(2));
        setPaymentNotes("");
        alert(
          `Payment recorded. Remaining due: ${formatCurrency(sanitizedRemaining)}`,
        );
      } else {
        alert("Payment recorded. Fine is fully paid.");
        handleCloseManageModal();
      }
    } catch (error) {
      console.error("Error recording payment:", error);
      alert("Failed to record payment");
    } finally {
      setIsRecordingPayment(false);
    }
  };

  const handleRenewLoan = async () => {
    if (!selectedFine?.loan_id) {
      alert("This fine has no loan linked for renewal.");
      return;
    }

    try {
      setIsRenewingLoan(true);
      const res = await fetch(`/api/loans/${selectedFine.loan_id}/renew`, {
        method: "POST",
      });
      const json = await res
        .json()
        .catch(() => ({ error: "Failed to renew loan" }));
      if (!res.ok) {
        alert(json.error || "Failed to renew loan");
        return;
      }
      alert(json.message || "Loan renewed successfully by admin");
      await fetchFines();
    } catch (error) {
      console.error("Error renewing loan:", error);
      alert("Failed to renew loan");
    } finally {
      setIsRenewingLoan(false);
    }
  };

  const handleWaive = async (fine: FineWithRelations) => {
    if (!confirm("Are you sure you want to waive this fine?")) return;

    try {
      const res = await fetch(`/api/fines/${fine.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: "waived" }),
      });

      if (res.ok) {
        fetchFines();
      } else {
        alert("Failed to waive fine");
      }
    } catch (error) {
      console.error("Error waiving fine:", error);
    }
  };

  const totalPages = Math.ceil(totalCount / limit);

  const getStatusBadge = (status?: string | null) => {
    const normalized = (status || "unpaid").toLowerCase();
    switch (normalized) {
      case "paid":
        return <Badge variant="success">Paid</Badge>;
      case "unpaid":
        return <Badge variant="danger">Unpaid</Badge>;
      case "waived":
        return <Badge variant="info">Waived</Badge>;
      default:
        return <Badge>{normalized}</Badge>;
    }
  };

  const formatDateTime = (value?: string | null) => {
    if (!value) return "-";
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) return "-";
    return parsed.toLocaleString();
  };

  const toAmount = (value: unknown): number => {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  };

  const tabs = [
    { key: "all", label: "All Fines" },
    { key: "unpaid", label: "Unpaid" },
    { key: "paid", label: "Paid" },
  ] as const;

  return (
    <div>
      <Header
        title="Fines & Penalties"
        subtitle="Manage library fines and overdue penalties"
      />

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        {/* Tabs */}
        <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center">
          <div className="overflow-x-auto">
            <div className="flex min-w-max rounded-lg bg-gray-100 p-1">
              {tabs.map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => {
                    setActiveTab(tab.key);
                    setPage(1);
                  }}
                  className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                    activeTab === tab.key
                      ? "bg-white text-gray-900 shadow-sm"
                      : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>
          <div className="hidden flex-1 lg:block" />
          <Button onClick={handleOpenModal} className="w-full sm:w-auto">
            <Plus className="w-4 h-4 mr-2" />
            Create Manual Fine
          </Button>
        </div>

        {/* Search */}
        <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 mb-6">
          <p className="text-sm text-gray-600 mb-3">
            Fine payments are recorded only as physical payments handled by
            admins.
          </p>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search fines by user, book, fine/member/loan ID, reason, or payment notes..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setPage(1);
              }}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Fines Table */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="divide-y divide-gray-200 md:hidden">
            {loading ? (
              <div className="px-6 py-12 text-center text-gray-500">
                <div className="flex justify-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1E3A5F]" />
                </div>
              </div>
            ) : errorMessage ? (
              <div className="px-6 py-12 text-center text-red-600">
                <AlertCircle className="w-12 h-12 mx-auto mb-4 text-red-300" />
                <p>{errorMessage}</p>
              </div>
            ) : fines.length === 0 ? (
              <div className="px-6 py-12 text-center text-gray-500">
                <AlertCircle className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                <p>No fines found</p>
              </div>
            ) : (
              fines.map((fine) => {
                const fineStatus = (fine.status || "unpaid").toLowerCase();
                const remainingDue = Math.max(0, toAmount(fine.fine_amount));
                const totalPaid = Math.max(
                  0,
                  toAmount(fine.total_paid ?? fine.payment_amount),
                );
                const totalFine = Math.max(
                  remainingDue,
                  toAmount(fine.total_fine_amount ?? remainingDue + totalPaid),
                );
                const userTotalDue = Math.max(0, toAmount(fine.user_total_due));

                return (
                  <div key={fine.id} className="space-y-4 p-4">
                    <div className="flex flex-wrap items-start justify-between gap-3">
                      <div className="min-w-0">
                        <p className="font-medium text-gray-900">
                          {fine.user_name || "Unknown User"}
                        </p>
                        <p className="truncate text-sm text-gray-500">
                          {fine.user_email}
                        </p>
                      </div>
                      {getStatusBadge(fineStatus)}
                    </div>

                    <div className="space-y-3 text-sm text-gray-600">
                      <div>
                        <p className="text-xs font-medium uppercase tracking-wide text-gray-400">
                          References
                        </p>
                        <p>Book: {fine.book_title || "-"}</p>
                        <p className="text-xs text-gray-500">Fine ID: {fine.id}</p>
                        <p className="text-xs text-gray-500">
                          Member ID: {fine.member_id || "-"}
                        </p>
                        <p className="text-xs text-gray-500">
                          Loan ID: {fine.loan_id || "-"}
                        </p>
                      </div>

                      <div>
                        <p className="text-xs font-medium uppercase tracking-wide text-gray-400">
                          Fine Details
                        </p>
                        <p className="font-medium text-gray-900">
                          {fine.reason || "Overdue fine"}
                        </p>
                        <p className="text-xs text-gray-500">
                          Current payment method: {fine.payment_method || "-"}
                        </p>
                      </div>

                      <div>
                        <p className="text-xs font-medium uppercase tracking-wide text-gray-400">
                          Dates
                        </p>
                        <p>Fine date: {formatDate(fine.fine_date)}</p>
                        <p>
                          Due date:{" "}
                          {fine.due_date ? formatDate(fine.due_date) : "-"}
                        </p>
                        <p>Paid at: {formatDateTime(fine.paid_at)}</p>
                        <p>
                          Payment date:{" "}
                          {fine.payment_date ? formatDate(fine.payment_date) : "-"}
                        </p>
                      </div>

                      <div>
                        <p className="text-xs font-medium uppercase tracking-wide text-gray-400">
                          Payment
                        </p>
                        <p className="font-semibold text-gray-900">
                          Current due: {formatCurrency(remainingDue)}
                        </p>
                        <p className="text-xs text-gray-500">
                          Original total fine: {formatCurrency(totalFine)}
                        </p>
                        <p className="text-xs text-gray-500">
                          Paid so far: {formatCurrency(totalPaid)}
                        </p>
                        <p className="text-xs text-gray-500">
                          User total due: {formatCurrency(userTotalDue)}
                        </p>
                        <p className="text-xs text-gray-500">
                          Payments count: {toAmount(fine.payment_count)}
                        </p>
                        <p className="text-xs text-gray-500">
                          Handled by: {fine.payment_handled_by || "-"}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center justify-end gap-2">
                      {fineStatus !== "paid" && fineStatus !== "waived" && (
                        <button
                          onClick={() => handleOpenManageModal(fine)}
                          className="rounded-lg p-2 transition-colors hover:bg-green-100"
                          title="Manage Payment & Renewal"
                        >
                          <Wallet className="h-4 w-4 text-green-600" />
                        </button>
                      )}
                      {fineStatus !== "waived" && (
                        <button
                          onClick={() => handleWaive(fine)}
                          className="rounded-lg p-2 transition-colors hover:bg-red-100"
                          title="Waive Fine"
                        >
                          <X className="h-4 w-4 text-red-600" />
                        </button>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>

          <div className="hidden overflow-x-auto md:block">
            <table className="w-full min-w-[1180px]">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                    User
                  </th>
                  <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                    References
                  </th>
                  <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                    Fine Details
                  </th>
                  <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                    Date Details
                  </th>
                  <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                    Payment Details
                  </th>
                  <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                    Status
                  </th>
                  <th className="text-right px-6 py-3 text-sm font-semibold text-gray-900">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td
                      colSpan={7}
                      className="px-6 py-12 text-center text-gray-500"
                    >
                      <div className="flex justify-center">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1E3A5F]" />
                      </div>
                    </td>
                  </tr>
                ) : errorMessage ? (
                  <tr>
                    <td
                      colSpan={7}
                      className="px-6 py-12 text-center text-red-600"
                    >
                      <AlertCircle className="w-12 h-12 mx-auto mb-4 text-red-300" />
                      <p>{errorMessage}</p>
                    </td>
                  </tr>
                ) : fines.length === 0 ? (
                  <tr>
                    <td
                      colSpan={7}
                      className="px-6 py-12 text-center text-gray-500"
                    >
                      <AlertCircle className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                      <p>No fines found</p>
                    </td>
                  </tr>
                ) : (
                  fines.map((fine) => {
                    const fineStatus = (fine.status || "unpaid").toLowerCase();
                    const remainingDue = Math.max(0, toAmount(fine.fine_amount));
                    const totalPaid = Math.max(
                      0,
                      toAmount(fine.total_paid ?? fine.payment_amount),
                    );
                    const totalFine = Math.max(
                      remainingDue,
                      toAmount(fine.total_fine_amount ?? remainingDue + totalPaid),
                    );
                    const userTotalDue = Math.max(0, toAmount(fine.user_total_due));
                    return (
                      <tr key={fine.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <div>
                            <p className="font-medium text-gray-900">
                              {fine.user_name || "Unknown User"}
                            </p>
                            <p className="text-sm text-gray-500">
                              {fine.user_email}
                            </p>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          <p>Book: {fine.book_title || "-"}</p>
                          <p className="text-xs text-gray-500">
                            Fine ID: {fine.id}
                          </p>
                          <p className="text-xs text-gray-500">
                            Member ID: {fine.member_id || "-"}
                          </p>
                          <p className="text-xs text-gray-500">
                            Loan ID: {fine.loan_id || "-"}
                          </p>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-700">
                          <p className="font-medium text-gray-900">
                            {fine.reason || "Overdue fine"}
                          </p>
                          <p className="text-xs text-gray-500">
                            Current payment method: {fine.payment_method || "-"}
                          </p>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          <p>Fine date: {formatDate(fine.fine_date)}</p>
                          <p>
                            Due date:{" "}
                            {fine.due_date ? formatDate(fine.due_date) : "-"}
                          </p>
                          <p>Paid at: {formatDateTime(fine.paid_at)}</p>
                          <p>
                            Payment date:{" "}
                            {fine.payment_date ? formatDate(fine.payment_date) : "-"}
                          </p>
                          <p>Created: {formatDateTime(fine.created_at)}</p>
                          <p>Updated: {formatDateTime(fine.updated_at)}</p>
                        </td>
                        <td className="px-6 py-4 font-semibold text-gray-900">
                          <p>Current due: {formatCurrency(remainingDue)}</p>
                          <p className="text-xs font-normal text-gray-500">
                            Original total fine: {formatCurrency(totalFine)}
                          </p>
                          <p className="text-xs font-normal text-gray-500">
                            Paid so far: {formatCurrency(totalPaid)}
                          </p>
                          <p className="text-xs font-normal text-gray-500">
                            User total due: {formatCurrency(userTotalDue)}
                          </p>
                          <p className="text-xs font-normal text-gray-500">
                            Payments count: {toAmount(fine.payment_count)}
                          </p>
                          <p className="text-xs font-normal text-gray-500">
                            Handled by: {fine.payment_handled_by || "-"}
                          </p>
                          <p className="text-xs font-normal text-gray-500">
                            Notes: {fine.payment_notes || "-"}
                          </p>
                        </td>
                        <td className="px-6 py-4">
                          {getStatusBadge(fineStatus)}
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center justify-end gap-2">
                            {fineStatus !== "paid" && fineStatus !== "waived" && (
                              <button
                                onClick={() => handleOpenManageModal(fine)}
                                className="p-2 hover:bg-green-100 rounded-lg transition-colors"
                                title="Manage Payment & Renewal"
                              >
                                <Wallet className="w-4 h-4 text-green-600" />
                              </button>
                            )}
                            {fineStatus !== "waived" && (
                              <button
                                onClick={() => handleWaive(fine)}
                                className="p-2 hover:bg-red-100 rounded-lg transition-colors"
                                title="Waive Fine"
                              >
                                <X className="w-4 h-4 text-red-600" />
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex flex-col gap-3 border-t border-gray-200 px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6">
              <p className="text-sm text-gray-500">
                Showing {(page - 1) * limit + 1} to{" "}
                {Math.min(page * limit, totalCount)} of {totalCount} fines
              </p>
              <div className="flex items-center justify-between gap-2 sm:justify-end">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-2 hover:bg-gray-100 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <span className="text-sm text-gray-600">
                  Page {page} of {totalPages}
                </span>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-2 hover:bg-gray-100 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Create Fine Modal */}
      <Modal
        isOpen={isManageModalOpen}
        onClose={handleCloseManageModal}
        title="Manage Fine Payment & Renewal"
        size="lg"
      >
        {selectedFine ? (
          <div className="space-y-5">
            <div className="rounded-lg border border-gray-200 p-4 space-y-2">
              <h3 className="font-semibold text-gray-900">Fine Payment</h3>
              <p className="text-sm text-gray-600">
                Member: {selectedFine.user_name || selectedFine.member_id}
              </p>
              <p className="text-sm text-gray-600">
                Book: {selectedFine.book_title || "-"}
              </p>
              <p className="text-sm text-gray-600">
                Total fine:{" "}
                {formatCurrency(
                  Math.max(
                    toAmount(selectedFine.total_fine_amount),
                    toAmount(selectedFine.fine_amount) +
                      toAmount(selectedFine.total_paid),
                  ),
                )}
              </p>
              <p className="text-sm text-gray-600">
                Remaining due: {formatCurrency(toAmount(selectedFine.fine_amount))}
              </p>
              <Input
                label="Payment Amount (LKR)"
                type="number"
                step="0.01"
                min="0"
                value={paymentInput}
                onChange={(e) => setPaymentInput(e.target.value)}
              />
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Payment Notes (Optional)
                </label>
                <textarea
                  value={paymentNotes}
                  onChange={(e) => setPaymentNotes(e.target.value)}
                  rows={2}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                />
              </div>
              <Button
                onClick={handleRecordPhysicalPayment}
                isLoading={isRecordingPayment}
                className="w-full sm:w-auto"
              >
                Record Physical Payment
              </Button>
            </div>

            <div className="rounded-lg border border-gray-200 p-4 space-y-2">
              <h3 className="font-semibold text-gray-900">Book Renewal</h3>
              <p className="text-sm text-gray-600">
                Renewal is handled by admin only.
              </p>
              <p className="text-sm text-gray-600">
                Loan ID: {selectedFine.loan_id || "-"}
              </p>
              <Button
                onClick={handleRenewLoan}
                isLoading={isRenewingLoan}
                disabled={!selectedFine.loan_id}
                variant="secondary"
                className="w-full sm:w-auto"
              >
                <RefreshCw className="w-4 h-4 mr-2" />
                Renew Loan
              </Button>
            </div>
          </div>
        ) : null}
      </Modal>

      <Modal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        title="Create Manual Fine"
        size="md"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <Select
            label="User"
            value={formData.member_id}
            onChange={(e) =>
              setFormData({ ...formData, member_id: e.target.value })
            }
            options={[
              { value: "", label: "Select User" },
              ...users.map((u) => ({ value: u.id, label: u.name })),
            ]}
            required
          />
          <Input
            label="Amount"
            type="number"
            step="0.01"
            min="0"
            value={formData.fine_amount}
            onChange={(e) =>
              setFormData({
                ...formData,
                fine_amount: parseFloat(e.target.value) || 0,
              })
            }
            required
          />
          <Input
            label="Fine Date"
            type="date"
            value={formData.fine_date}
            onChange={(e) =>
              setFormData({ ...formData, fine_date: e.target.value })
            }
            required
          />
          <Input
            label="Due Date (Optional)"
            type="date"
            value={formData.due_date}
            onChange={(e) =>
              setFormData({ ...formData, due_date: e.target.value })
            }
          />
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Reason (Optional)
            </label>
            <textarea
              value={formData.reason}
              onChange={(e) =>
                setFormData({ ...formData, reason: e.target.value })
              }
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
            />
          </div>
          <div className="flex flex-col-reverse gap-3 pt-4 sm:flex-row sm:justify-end">
            <Button
              type="button"
              variant="secondary"
              className="w-full sm:w-auto"
              onClick={handleCloseModal}
            >
              Cancel
            </Button>
            <Button type="submit" isLoading={isSubmitting} className="w-full sm:w-auto">
              Create Fine
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
