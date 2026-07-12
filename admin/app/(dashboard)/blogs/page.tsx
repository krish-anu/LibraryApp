"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Header } from "@/components/layout/header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Modal } from "@/components/ui/modal";
import { Select } from "@/components/ui/select";
import type { BlogPost } from "@/lib/types";
import {
  ChevronLeft,
  ChevronRight,
  Edit,
  FileText,
  Plus,
  Search,
  Trash2,
} from "lucide-react";

interface BlogFormData {
  title: string;
  excerpt: string;
  content: string;
  author: string;
  category: string;
  cover_image: string;
  read_minutes: number;
  published: boolean;
  published_at: string;
}

const initialFormData: BlogFormData = {
  title: "",
  excerpt: "",
  content: "",
  author: "Library Team",
  category: "Library",
  cover_image: "",
  read_minutes: 3,
  published: true,
  published_at: "",
};

function toDateTimeLocal(value?: string) {
  if (!value) return "";
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return "";
  return new Date(parsed.getTime() - parsed.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
}

function toPayloadDate(value: string) {
  return value ? new Date(value).toISOString() : new Date().toISOString();
}

function blogToFormData(blog: BlogPost): BlogFormData {
  return {
    title: blog.title,
    excerpt: blog.excerpt,
    content: blog.content,
    author: blog.author,
    category: blog.category,
    cover_image: blog.cover_image || "",
    read_minutes: blog.read_minutes,
    published: blog.published,
    published_at: toDateTimeLocal(blog.published_at),
  };
}

function formatDate(value: string) {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return "-";
  return parsed.toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export default function BlogsPage() {
  const [blogs, setBlogs] = useState<BlogPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const limit = 10;

  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBlog, setEditingBlog] = useState<BlogPost | null>(null);
  const [formData, setFormData] = useState<BlogFormData>(initialFormData);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const categories = useMemo(
    () => Array.from(new Set(blogs.map((blog) => blog.category).filter(Boolean))).sort(),
    [blogs],
  );

  const fetchBlogs = useCallback(async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: limit.toString(),
      });
      if (searchQuery) params.append("search", searchQuery);
      if (statusFilter) params.append("status", statusFilter);
      if (categoryFilter) params.append("category", categoryFilter);

      const res = await fetch(`/api/blogs?${params}`);
      const json = await res.json();
      setBlogs(json.data || []);
      setTotalCount(json.totalCount || 0);
    } catch (error) {
      console.error("Error fetching blogs:", error);
    } finally {
      setLoading(false);
    }
  }, [categoryFilter, limit, page, searchQuery, statusFilter]);

  useEffect(() => {
    fetchBlogs();
  }, [fetchBlogs]);

  const handleOpenModal = (blog?: BlogPost) => {
    if (blog) {
      setEditingBlog(blog);
      setFormData(blogToFormData(blog));
    } else {
      setEditingBlog(null);
      setFormData({
        ...initialFormData,
        published_at: toDateTimeLocal(new Date().toISOString()),
      });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingBlog(null);
    setFormData(initialFormData);
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setIsSubmitting(true);

    try {
      const url = editingBlog ? `/api/blogs/${editingBlog.id}` : "/api/blogs";
      const method = editingBlog ? "PUT" : "POST";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...formData,
          published_at: toPayloadDate(formData.published_at),
        }),
      });

      if (!res.ok) {
        const error = await res.json();
        alert(error.error || "Failed to save blog");
        return;
      }

      handleCloseModal();
      fetchBlogs();
    } catch (error) {
      console.error("Error saving blog:", error);
      alert("Failed to save blog");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (blog: BlogPost) => {
    if (!confirm(`Delete "${blog.title}"?`)) return;

    try {
      const res = await fetch(`/api/blogs/${blog.id}`, { method: "DELETE" });
      if (!res.ok) {
        alert("Failed to delete blog");
        return;
      }
      fetchBlogs();
    } catch (error) {
      console.error("Error deleting blog:", error);
      alert("Failed to delete blog");
    }
  };

  const totalPages = Math.ceil(totalCount / limit);

  return (
    <div>
      <Header title="Blogs" subtitle="Create and manage mobile app blog posts" />

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        <div className="mb-6 rounded-xl border border-gray-100 bg-white p-4 shadow-sm">
          <div className="flex flex-col gap-4 xl:flex-row xl:items-center">
            <div className="relative min-w-0 flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search blogs..."
                value={searchQuery}
                onChange={(event) => {
                  setSearchQuery(event.target.value);
                  setPage(1);
                }}
                className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="flex flex-col gap-3 sm:flex-row xl:flex-none">
              <Select
                value={statusFilter}
                onChange={(event) => {
                  setStatusFilter(event.target.value);
                  setPage(1);
                }}
                options={[
                  { value: "", label: "All Status" },
                  { value: "published", label: "Published" },
                  { value: "draft", label: "Draft" },
                ]}
                className="w-full sm:w-40"
              />
              <Select
                value={categoryFilter}
                onChange={(event) => {
                  setCategoryFilter(event.target.value);
                  setPage(1);
                }}
                options={[
                  { value: "", label: "All Categories" },
                  ...categories.map((category) => ({
                    value: category,
                    label: category,
                  })),
                ]}
                className="w-full sm:w-44"
              />
              <Button onClick={() => handleOpenModal()} className="w-full sm:w-auto">
                <Plus className="mr-2 h-4 w-4" />
                Add Blog
              </Button>
            </div>
          </div>
        </div>

        <div className="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm">
          <div className="divide-y divide-gray-200 md:hidden">
            {loading ? (
              <LoadingBlock />
            ) : blogs.length === 0 ? (
              <EmptyBlock />
            ) : (
              blogs.map((blog) => (
                <div key={blog.id} className="space-y-4 p-4">
                  <div className="flex gap-3">
                    <BlogThumb blog={blog} />
                    <div className="min-w-0 flex-1">
                      <div className="mb-2 flex items-center gap-2">
                        <Badge variant={blog.published ? "success" : "warning"}>
                          {blog.published ? "Published" : "Draft"}
                        </Badge>
                        <span className="text-xs text-gray-500">
                          {blog.category}
                        </span>
                      </div>
                      <p className="font-medium text-gray-900">{blog.title}</p>
                      <p className="mt-1 line-clamp-2 text-sm text-gray-500">
                        {blog.excerpt || "-"}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>{blog.author}</span>
                    <span>{blog.read_minutes} min read</span>
                  </div>
                  <ActionButtons
                    onEdit={() => handleOpenModal(blog)}
                    onDelete={() => handleDelete(blog)}
                  />
                </div>
              ))
            )}
          </div>

          <div className="hidden overflow-x-auto md:block">
            <table className="w-full min-w-220">
              <thead className="border-b border-gray-200 bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">
                    Blog
                  </th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">
                    Category
                  </th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">
                    Author
                  </th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">
                    Published
                  </th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">
                    Status
                  </th>
                  <th className="px-6 py-3 text-right text-sm font-semibold text-gray-900">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan={6}>
                      <LoadingBlock />
                    </td>
                  </tr>
                ) : blogs.length === 0 ? (
                  <tr>
                    <td colSpan={6}>
                      <EmptyBlock />
                    </td>
                  </tr>
                ) : (
                  blogs.map((blog) => (
                    <tr key={blog.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <BlogThumb blog={blog} />
                          <div className="min-w-0">
                            <p className="font-medium text-gray-900">
                              {blog.title}
                            </p>
                            <p className="max-w-xl truncate text-sm text-gray-500">
                              {blog.excerpt || "-"}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {blog.category}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {blog.author}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {formatDate(blog.published_at)}
                      </td>
                      <td className="px-6 py-4">
                        <Badge variant={blog.published ? "success" : "warning"}>
                          {blog.published ? "Published" : "Draft"}
                        </Badge>
                      </td>
                      <td className="px-6 py-4">
                        <ActionButtons
                          onEdit={() => handleOpenModal(blog)}
                          onDelete={() => handleDelete(blog)}
                        />
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <Pagination
            page={page}
            totalPages={totalPages}
            totalCount={totalCount}
            limit={limit}
            label="blogs"
            onPrevious={() => setPage((current) => Math.max(1, current - 1))}
            onNext={() =>
              setPage((current) => Math.min(totalPages, current + 1))
            }
          />
        </div>
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        title={editingBlog ? "Edit Blog" : "Add Blog"}
        size="xl"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Title"
            value={formData.title}
            onChange={(event) =>
              setFormData({ ...formData, title: event.target.value })
            }
            required
          />
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <Input
              label="Author"
              value={formData.author}
              onChange={(event) =>
                setFormData({ ...formData, author: event.target.value })
              }
              required
            />
            <Input
              label="Category"
              value={formData.category}
              onChange={(event) =>
                setFormData({ ...formData, category: event.target.value })
              }
              required
            />
          </div>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <Input
              label="Read Minutes"
              type="number"
              min="1"
              value={formData.read_minutes}
              onChange={(event) =>
                setFormData({
                  ...formData,
                  read_minutes: parseInt(event.target.value) || 1,
                })
              }
            />
            <Input
              label="Publish Date"
              type="datetime-local"
              value={formData.published_at}
              onChange={(event) =>
                setFormData({ ...formData, published_at: event.target.value })
              }
            />
            <Select
              label="Status"
              value={String(formData.published)}
              onChange={(event) =>
                setFormData({
                  ...formData,
                  published: event.target.value === "true",
                })
              }
              options={[
                { value: "true", label: "Published" },
                { value: "false", label: "Draft" },
              ]}
            />
          </div>
          <Input
            label="Cover Image URL"
            value={formData.cover_image}
            onChange={(event) =>
              setFormData({ ...formData, cover_image: event.target.value })
            }
          />
          <TextArea
            label="Excerpt"
            rows={3}
            value={formData.excerpt}
            onChange={(value) => setFormData({ ...formData, excerpt: value })}
          />
          <TextArea
            label="Content"
            rows={8}
            value={formData.content}
            onChange={(value) => setFormData({ ...formData, content: value })}
          />
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
              {editingBlog ? "Update Blog" : "Add Blog"}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

function BlogThumb({ blog }: { blog: BlogPost }) {
  return (
    <div className="flex h-16 w-24 shrink-0 items-center justify-center overflow-hidden rounded bg-gray-100">
      {blog.cover_image ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={blog.cover_image}
          alt={blog.title}
          className="h-full w-full object-cover"
        />
      ) : (
        <FileText className="h-6 w-6 text-gray-400" />
      )}
    </div>
  );
}

function ActionButtons({
  onEdit,
  onDelete,
}: {
  onEdit: () => void;
  onDelete: () => void;
}) {
  return (
    <div className="flex items-center justify-end gap-2">
      <button
        type="button"
        onClick={onEdit}
        className="rounded-lg p-2 transition-colors hover:bg-gray-100"
      >
        <Edit className="h-4 w-4 text-gray-600" />
      </button>
      <button
        type="button"
        onClick={onDelete}
        className="rounded-lg p-2 transition-colors hover:bg-red-100"
      >
        <Trash2 className="h-4 w-4 text-red-600" />
      </button>
    </div>
  );
}

function TextArea({
  label,
  rows,
  value,
  onChange,
}: {
  label: string;
  rows: number;
  value: string;
  onChange: (value: string) => void;
}) {
  return (
    <div>
      <label className="mb-1 block text-sm font-medium text-gray-700">
        {label}
      </label>
      <textarea
        rows={rows}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-lg border border-gray-300 px-3 py-2 outline-none transition-colors focus:border-blue-500 focus:ring-2 focus:ring-blue-500"
      />
    </div>
  );
}

function LoadingBlock() {
  return (
    <div className="px-6 py-12 text-center text-gray-500">
      <div className="flex justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-[#1E3A5F]" />
      </div>
    </div>
  );
}

function EmptyBlock() {
  return (
    <div className="px-6 py-12 text-center text-gray-500">
      <FileText className="mx-auto mb-4 h-12 w-12 text-gray-300" />
      <p>No blogs found</p>
    </div>
  );
}

function Pagination({
  page,
  totalPages,
  totalCount,
  limit,
  label,
  onPrevious,
  onNext,
}: {
  page: number;
  totalPages: number;
  totalCount: number;
  limit: number;
  label: string;
  onPrevious: () => void;
  onNext: () => void;
}) {
  if (totalPages <= 1) return null;

  return (
    <div className="flex flex-col gap-3 border-t border-gray-200 px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6">
      <p className="text-sm text-gray-500">
        Showing {(page - 1) * limit + 1} to {Math.min(page * limit, totalCount)}{" "}
        of {totalCount} {label}
      </p>
      <div className="flex items-center justify-between gap-2 sm:justify-end">
        <button
          type="button"
          onClick={onPrevious}
          disabled={page === 1}
          className="rounded-lg p-2 hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-50"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>
        <span className="text-sm text-gray-600">
          Page {page} of {totalPages}
        </span>
        <button
          type="button"
          onClick={onNext}
          disabled={page === totalPages}
          className="rounded-lg p-2 hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-50"
        >
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}
