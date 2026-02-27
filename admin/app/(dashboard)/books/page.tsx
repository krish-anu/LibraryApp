"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Modal } from "@/components/ui/modal";
import { formatDate } from "@/lib/utils";
import { Book } from "@/lib/types";
import {
  Plus,
  Search,
  Edit,
  Trash2,
  ChevronLeft,
  ChevronRight,
  BookOpen,
} from "lucide-react";

interface BookFormData {
  title: string;
  author: string;
  category_id: string;
  description: string;
  copies_owned: number;
  publication_year: number;
  image: string;
  language: string;
  pages: number;
}

const initialFormData: BookFormData = {
  title: "",
  author: "",
  category_id: "",
  description: "",
  copies_owned: 1,
  publication_year: new Date().getFullYear(),
  image: "",
  language: "English",
  pages: 0,
};

export default function BooksPage() {
  const [books, setBooks] = useState<Book[]>([]);
  const [categories, setCategories] = useState<{ id: string; name: string }[]>(
    [],
  );
  const [loading, setLoading] = useState(true);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const limit = 10;

  // Filters
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");

  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBook, setEditingBook] = useState<Book | null>(null);
  const [formData, setFormData] = useState<BookFormData>(initialFormData);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [coverPreview, setCoverPreview] = useState<string | null>(null);

  useEffect(() => {
    fetchCategories();
  }, []);

  useEffect(() => {
    fetchBooks();
  }, [page, searchQuery, statusFilter, categoryFilter]);

  const fetchCategories = async () => {
    try {
      const res = await fetch("/api/categories");
      const json = await res.json();
      setCategories(json.data || []);
    } catch (error) {
      console.error("Error fetching categories:", error);
    }
  };

  const fetchBooks = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: limit.toString(),
      });
      if (searchQuery) params.append("search", searchQuery);
      if (statusFilter) params.append("status", statusFilter);
      if (categoryFilter) params.append("category", categoryFilter);

      const res = await fetch(`/api/books?${params}`);
      const json = await res.json();
      setBooks(json.data || []);
      setTotalCount(json.totalCount || 0);
    } catch (error) {
      console.error("Error fetching books:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (book?: Book) => {
    if (book) {
      setEditingBook(book);
      setFormData({
        title: book.title,
        author: book.author,
        category_id: book.category_id || "",
        description: book.description || "",
        copies_owned: book.copies_owned,
        publication_year: book.publication_year || new Date().getFullYear(),
        image: book.image || "",
        language: book.language || "English",
        pages: book.pages || 0,
      });
      setCoverFile(null);
      setCoverPreview(book.image || null);
    } else {
      setEditingBook(null);
      setFormData(initialFormData);
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingBook(null);
    setFormData(initialFormData);
    if (coverPreview && coverPreview.startsWith("blob:")) {
      URL.revokeObjectURL(coverPreview);
    }
    setCoverFile(null);
    setCoverPreview(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      // If a new cover file was selected, upload it first and capture image URL
      let uploadedImageUrl = formData.image;
      if (coverFile) {
        try {
          const form = new FormData();
          form.append("file", coverFile);
          form.append("filename", coverFile.name);

          const uploadRes = await fetch("/api/storage/upload", {
            method: "POST",
            body: form,
          });
          if (!uploadRes.ok) {
            const text = await uploadRes.text();
            console.error("Upload failed:", uploadRes.status, text);
            throw new Error(`Upload failed: ${uploadRes.status} ${text}`);
          }
          const uploadJson = await uploadRes.json();
          const publicUrl: string = uploadJson.publicUrl;
          uploadedImageUrl = publicUrl;
        } catch (err) {
          console.error("Cover upload failed:", err);
          alert("Failed to upload cover image");
          setIsSubmitting(false);
          return;
        }
      }

      const url = editingBook ? `/api/books/${editingBook.id}` : "/api/books";
      const method = editingBook ? "PUT" : "POST";

      const payload = { ...formData, image: uploadedImageUrl };

      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        handleCloseModal();
        fetchBooks();
      } else {
        const error = await res.json();
        alert(error.error || "Failed to save book");
      }
    } catch (error) {
      console.error("Error saving book:", error);
      alert("Failed to save book");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (book: Book) => {
    if (!confirm(`Are you sure you want to delete "${book.title}"?`)) return;

    try {
      const res = await fetch(`/api/books/${book.id}`, { method: "DELETE" });
      if (res.ok) {
        fetchBooks();
      } else {
        alert("Failed to delete book");
      }
    } catch (error) {
      console.error("Error deleting book:", error);
    }
  };

  const totalPages = Math.ceil(totalCount / limit);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "available":
        return <Badge variant="success">Available</Badge>;
      case "checked_out":
        return <Badge variant="warning">Checked Out</Badge>;
      case "reserved":
        return <Badge variant="info">Reserved</Badge>;
      default:
        return <Badge>{status}</Badge>;
    }
  };

  return (
    <div>
      <Header
        title="Book Inventory"
        subtitle="Manage your library's book collection"
      />

      <div className="p-8">
        {/* Filters */}
        <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 mb-6">
          <div className="flex flex-wrap items-center gap-4">
            <div className="relative flex-1 min-w-50">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search books..."
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setPage(1);
                }}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <Select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setPage(1);
              }}
              options={[
                { value: "", label: "All Status" },
                { value: "available", label: "Available" },
                { value: "checked_out", label: "Checked Out" },
                { value: "reserved", label: "Reserved" },
              ]}
              className="w-40"
            />
            <Select
              value={categoryFilter}
              onChange={(e) => {
                setCategoryFilter(e.target.value);
                setPage(1);
              }}
              options={[
                { value: "", label: "All Categories" },
                ...categories.map((c) => ({ value: c.id, label: c.name })),
              ]}
              className="w-40"
            />
            <Button onClick={() => handleOpenModal()}>
              <Plus className="w-4 h-4 mr-2" />
              Add New Book
            </Button>
          </div>
        </div>

        {/* Books Table */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  Book
                </th>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  Category
                </th>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  Copies
                </th>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  Year
                </th>
                <th className="text-left px-6 py-3 text-sm font-semibold text-gray-900">
                  Rating
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
                    colSpan={6}
                    className="px-6 py-12 text-center text-gray-500"
                  >
                    <div className="flex justify-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1E3A5F]" />
                    </div>
                  </td>
                </tr>
              ) : books.length === 0 ? (
                <tr>
                  <td
                    colSpan={6}
                    className="px-6 py-12 text-center text-gray-500"
                  >
                    <BookOpen className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                    <p>No books found</p>
                  </td>
                </tr>
              ) : (
                books.map((book) => (
                  <tr key={book.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-14 bg-gray-200 rounded flex items-center justify-center overflow-hidden">
                          {book.image ? (
                            <img
                              src={book.image}
                              alt={book.title}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <BookOpen className="w-5 h-5 text-gray-400" />
                          )}
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">
                            {book.title}
                          </p>
                          <p className="text-sm text-gray-500">{book.author}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {book.category || "-"}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {book.copies_owned}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {book.publication_year || "-"}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {typeof book.rating === "number"
                        ? book.rating.toFixed(1)
                        : "-"}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleOpenModal(book)}
                          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        >
                          <Edit className="w-4 h-4 text-gray-600" />
                        </button>
                        <button
                          onClick={() => handleDelete(book)}
                          className="p-2 hover:bg-red-100 rounded-lg transition-colors"
                        >
                          <Trash2 className="w-4 h-4 text-red-600" />
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
                {Math.min(page * limit, totalCount)} of {totalCount} books
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

      {/* Add/Edit Book Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        title={editingBook ? "Edit Book" : "Add New Book"}
        size="lg"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Title"
              value={formData.title}
              onChange={(e) =>
                setFormData({ ...formData, title: e.target.value })
              }
              required
            />
            <Input
              label="Author"
              value={formData.author}
              onChange={(e) =>
                setFormData({ ...formData, author: e.target.value })
              }
              required
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Category"
              value={formData.category_id}
              onChange={(e) =>
                setFormData({ ...formData, category_id: e.target.value })
              }
              options={[
                { value: "", label: "Select Category" },
                ...categories.map((c) => ({ value: c.id, label: c.name })),
              ]}
            />
            <Input
              label="Publication Year"
              type="number"
              min="1000"
              max={new Date().getFullYear() + 1}
              value={formData.publication_year}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  publication_year:
                    parseInt(e.target.value) || new Date().getFullYear(),
                })
              }
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Input
              label="Copies Owned"
              type="number"
              min="0"
              value={formData.copies_owned}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  copies_owned: parseInt(e.target.value) || 0,
                })
              }
              required
            />
            <Input
              label="Pages"
              type="number"
              min="0"
              value={formData.pages}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  pages: parseInt(e.target.value) || 0,
                })
              }
            />
            <Input
              label="Language"
              value={formData.language}
              onChange={(e) =>
                setFormData({ ...formData, language: e.target.value })
              }
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Cover Image
            </label>
            <div className="flex items-center gap-4">
              <div className="w-24 h-32 bg-gray-100 rounded overflow-hidden flex items-center justify-center border">
                {coverPreview ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={coverPreview}
                    alt="cover"
                    className="w-full h-full object-cover"
                  />
                ) : formData.image ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={formData.image}
                    alt="cover"
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="text-gray-400 text-xs">No image</div>
                )}
              </div>
              <div className="flex-1">
                <input
                  type="file"
                  accept="image/*"
                  onChange={(e) => {
                    const f = e.target.files?.[0] || null;
                    setCoverFile(f);
                    if (f) {
                      if (coverPreview && coverPreview.startsWith("blob:")) {
                        URL.revokeObjectURL(coverPreview);
                      }
                      setCoverPreview(URL.createObjectURL(f));
                    } else {
                      if (coverPreview && coverPreview.startsWith("blob:")) {
                        URL.revokeObjectURL(coverPreview);
                      }
                      setCoverPreview(formData.image || null);
                    }
                  }}
                />
                <p className="text-sm text-gray-500 mt-1">
                  Upload a cover image (optional). Selecting a file will replace
                  the image URL.
                </p>
              </div>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
            />
          </div>
          <div className="flex justify-end gap-3 pt-4">
            <Button
              type="button"
              variant="secondary"
              onClick={handleCloseModal}
            >
              Cancel
            </Button>
            <Button type="submit" isLoading={isSubmitting}>
              {editingBook ? "Update Book" : "Add Book"}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
