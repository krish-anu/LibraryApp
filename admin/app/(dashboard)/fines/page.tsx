"use client";

import { useEffect, useState } from "react";
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
  Check,
  X,
} from "lucide-react";

interface FineWithRelations extends Fine {
  user_name?: string;
  user_email?: string;
  book_title?: string;
}

interface FineFormData {
  member_id: string;
  loan_id: string;
  fine_amount: number;
  fine_date: string;
}

const initialFormData: FineFormData = {
  member_id: "",
  loan_id: "",
  fine_amount: 0,
  fine_date: new Date().toISOString().split("T")[0],
};

export default function FinesPage() {
  const [fines, setFines] = useState<FineWithRelations[]>([]);
  const [users, setUsers] = useState<{ id: string; name: string }[]>([]);
  const [books, setBooks] = useState<{ id: string; title: string }[]>([]);
  const [loading, setLoading] = useState(true);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const limit = 10;

  // Filters
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("");

  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState<FineFormData>(initialFormData);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Tab state
  const [activeTab, setActiveTab] = useState<"all" | "unpaid" | "paid">("all");

  useEffect(() => {
    fetchUsersAndBooks();
  }, []);

  useEffect(() => {
    fetchFines();
  }, [page, searchQuery, statusFilter, activeTab]);

  const fetchUsersAndBooks = async () => {
    try {
      const [usersRes, booksRes] = await Promise.all([
        fetch("/api/users?limit=100"),
        fetch("/api/books?limit=100"),
      ]);
      const usersJson = await usersRes.json();
      const booksJson = await booksRes.json();
      setUsers(usersJson.data || []);
      setBooks(booksJson.data || []);
    } catch (error) {
      console.error("Error fetching users/books:", error);
    }
  };

  const fetchFines = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: limit.toString(),
      });
      if (searchQuery) params.append("search", searchQuery);
      if (activeTab !== "all") params.append("status", activeTab);

      const res = await fetch(`/api/fines?${params}`);
      const json = await res.json();
      setFines(json.data || []);
      setTotalCount(json.totalCount || 0);
    } catch (error) {
      console.error("Error fetching fines:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = () => {
    setFormData(initialFormData);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setFormData(initialFormData);
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

  const handleMarkPaid = async (fine: FineWithRelations) => {
    try {
      const res = await fetch(`/api/fines/${fine.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          status: "paid",
          paid_at: new Date().toISOString(),
        }),
      });

      if (res.ok) {
        fetchFines();
      } else {
        alert("Failed to update fine");
      }
    } catch (error) {
      console.error("Error updating fine:", error);
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

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "paid":
        return <Badge variant="success">Paid</Badge>;
      case "unpaid":
        return <Badge variant="danger">Unpaid</Badge>;
      case "waived":
        return <Badge variant="info">Waived</Badge>;
      default:
        return <Badge>{status}</Badge>;
    }
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

      <div className="p-8">
        {/* Tabs */}
        <div className="flex items-center gap-4 mb-6">
          <div className="flex bg-gray-100 rounded-lg p-1">
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
          <div className="flex-1" />
          <Button onClick={handleOpenModal}>
            <Plus className="w-4 h-4 mr-2" />
            Create Manual Fine
          </Button>
        </div>

        {/* Search */}
        <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 mb-6">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search fines by user or book..."
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
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  User
                </th>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  Book
                </th>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  Amount
                </th>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  Date
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
                    colSpan={5}
                    className="px-6 py-12 text-center text-gray-500"
                  >
                    <div className="flex justify-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1E3A5F]" />
                    </div>
                  </td>
                </tr>
              ) : fines.length === 0 ? (
                <tr>
                  <td
                    colSpan={5}
                    className="px-6 py-12 text-center text-gray-500"
                  >
                    <AlertCircle className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                    <p>No fines found</p>
                  </td>
                </tr>
              ) : (
                fines.map((fine) => (
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
                      {fine.book_title || "-"}
                    </td>
                    <td className="px-6 py-4 font-semibold text-gray-900">
                      {formatCurrency(fine.fine_amount)}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {formatDate(fine.fine_date)}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleMarkPaid(fine)}
                          className="p-2 hover:bg-green-100 rounded-lg transition-colors"
                          title="Mark as Paid"
                        >
                          <Check className="w-4 h-4 text-green-600" />
                        </button>
                        <button
                          onClick={() => handleWaive(fine)}
                          className="p-2 hover:bg-red-100 rounded-lg transition-colors"
                          title="Delete Fine"
                        >
                          <X className="w-4 h-4 text-red-600" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200">
              <p className="text-sm text-gray-500">
                Showing {(page - 1) * limit + 1} to{" "}
                {Math.min(page * limit, totalCount)} of {totalCount} fines
              </p>
              <div className="flex items-center gap-2">
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
          <div className="flex justify-end gap-3 pt-4">
            <Button
              type="button"
              variant="secondary"
              onClick={handleCloseModal}
            >
              Cancel
            </Button>
            <Button type="submit" isLoading={isSubmitting}>
              Create Fine
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
