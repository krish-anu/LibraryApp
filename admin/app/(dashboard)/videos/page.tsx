"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Header } from "@/components/layout/header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Modal } from "@/components/ui/modal";
import { Select } from "@/components/ui/select";
import type { VideoPost } from "@/lib/types";
import {
  ChevronLeft,
  ChevronRight,
  Edit,
  PlayCircle,
  Plus,
  Search,
  Trash2,
  Video,
} from "lucide-react";

interface VideoFormData {
  title: string;
  description: string;
  youtube_video_id: string;
  speaker: string;
  category: string;
  duration: string;
  thumbnail_url: string;
  published: boolean;
  published_at: string;
}

const initialFormData: VideoFormData = {
  title: "",
  description: "",
  youtube_video_id: "",
  speaker: "Library Team",
  category: "Learning",
  duration: "",
  thumbnail_url: "",
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

function videoToFormData(video: VideoPost): VideoFormData {
  return {
    title: video.title,
    description: video.description,
    youtube_video_id: video.youtube_video_id,
    speaker: video.speaker,
    category: video.category,
    duration: video.duration,
    thumbnail_url: video.thumbnail_url || "",
    published: video.published,
    published_at: toDateTimeLocal(video.published_at),
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

function thumbnailFor(video: Pick<VideoPost, "youtube_video_id" | "thumbnail_url">) {
  return (
    video.thumbnail_url ||
    (video.youtube_video_id
      ? `https://img.youtube.com/vi/${video.youtube_video_id}/hqdefault.jpg`
      : "")
  );
}

function extractYoutubeId(value: string) {
  const trimmed = value.trim();
  if (!trimmed.includes("youtube.com") && !trimmed.includes("youtu.be")) {
    return trimmed;
  }

  try {
    const url = new URL(trimmed);
    if (url.hostname.includes("youtu.be")) {
      return url.pathname.replace("/", "");
    }
    return url.searchParams.get("v") || url.pathname.split("/").pop() || trimmed;
  } catch {
    return trimmed;
  }
}

export default function VideosPage() {
  const [videos, setVideos] = useState<VideoPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const limit = 10;

  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingVideo, setEditingVideo] = useState<VideoPost | null>(null);
  const [formData, setFormData] = useState<VideoFormData>(initialFormData);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const categories = useMemo(
    () =>
      Array.from(new Set(videos.map((video) => video.category).filter(Boolean))).sort(),
    [videos],
  );

  const fetchVideos = useCallback(async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: limit.toString(),
      });
      if (searchQuery) params.append("search", searchQuery);
      if (statusFilter) params.append("status", statusFilter);
      if (categoryFilter) params.append("category", categoryFilter);

      const res = await fetch(`/api/videos?${params}`);
      const json = await res.json();
      setVideos(json.data || []);
      setTotalCount(json.totalCount || 0);
    } catch (error) {
      console.error("Error fetching videos:", error);
    } finally {
      setLoading(false);
    }
  }, [categoryFilter, limit, page, searchQuery, statusFilter]);

  useEffect(() => {
    fetchVideos();
  }, [fetchVideos]);

  const handleOpenModal = (video?: VideoPost) => {
    if (video) {
      setEditingVideo(video);
      setFormData(videoToFormData(video));
    } else {
      setEditingVideo(null);
      setFormData({
        ...initialFormData,
        published_at: toDateTimeLocal(new Date().toISOString()),
      });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingVideo(null);
    setFormData(initialFormData);
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setIsSubmitting(true);

    try {
      const url = editingVideo
        ? `/api/videos/${editingVideo.id}`
        : "/api/videos";
      const method = editingVideo ? "PUT" : "POST";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...formData,
          youtube_video_id: extractYoutubeId(formData.youtube_video_id),
          published_at: toPayloadDate(formData.published_at),
        }),
      });

      if (!res.ok) {
        const error = await res.json();
        alert(error.error || "Failed to save video");
        return;
      }

      handleCloseModal();
      fetchVideos();
    } catch (error) {
      console.error("Error saving video:", error);
      alert("Failed to save video");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (video: VideoPost) => {
    if (!confirm(`Delete "${video.title}"?`)) return;

    try {
      const res = await fetch(`/api/videos/${video.id}`, { method: "DELETE" });
      if (!res.ok) {
        alert("Failed to delete video");
        return;
      }
      fetchVideos();
    } catch (error) {
      console.error("Error deleting video:", error);
      alert("Failed to delete video");
    }
  };

  const totalPages = Math.ceil(totalCount / limit);

  return (
    <div>
      <Header title="Videos" subtitle="Manage embedded YouTube videos" />

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        <div className="mb-6 rounded-xl border border-gray-100 bg-white p-4 shadow-sm">
          <div className="flex flex-col gap-4 xl:flex-row xl:items-center">
            <div className="relative min-w-0 flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search videos..."
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
                Add Video
              </Button>
            </div>
          </div>
        </div>

        <div className="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm">
          <div className="divide-y divide-gray-200 md:hidden">
            {loading ? (
              <LoadingBlock />
            ) : videos.length === 0 ? (
              <EmptyBlock />
            ) : (
              videos.map((video) => (
                <div key={video.id} className="space-y-4 p-4">
                  <div className="flex gap-3">
                    <VideoThumb video={video} />
                    <div className="min-w-0 flex-1">
                      <div className="mb-2 flex items-center gap-2">
                        <Badge variant={video.published ? "success" : "warning"}>
                          {video.published ? "Published" : "Draft"}
                        </Badge>
                        <span className="text-xs text-gray-500">
                          {video.category}
                        </span>
                      </div>
                      <p className="font-medium text-gray-900">{video.title}</p>
                      <p className="mt-1 line-clamp-2 text-sm text-gray-500">
                        {video.description || "-"}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>{video.speaker}</span>
                    <span>{video.duration || "-"}</span>
                  </div>
                  <ActionButtons
                    onEdit={() => handleOpenModal(video)}
                    onDelete={() => handleDelete(video)}
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
                    Video
                  </th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">
                    Category
                  </th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">
                    Speaker
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
                ) : videos.length === 0 ? (
                  <tr>
                    <td colSpan={6}>
                      <EmptyBlock />
                    </td>
                  </tr>
                ) : (
                  videos.map((video) => (
                    <tr key={video.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <VideoThumb video={video} />
                          <div className="min-w-0">
                            <p className="font-medium text-gray-900">
                              {video.title}
                            </p>
                            <p className="max-w-xl truncate text-sm text-gray-500">
                              {video.youtube_video_id}
                              {video.duration ? ` · ${video.duration}` : ""}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {video.category}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {video.speaker}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {formatDate(video.published_at)}
                      </td>
                      <td className="px-6 py-4">
                        <Badge variant={video.published ? "success" : "warning"}>
                          {video.published ? "Published" : "Draft"}
                        </Badge>
                      </td>
                      <td className="px-6 py-4">
                        <ActionButtons
                          onEdit={() => handleOpenModal(video)}
                          onDelete={() => handleDelete(video)}
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
            label="videos"
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
        title={editingVideo ? "Edit Video" : "Add Video"}
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
              label="YouTube Video ID or URL"
              value={formData.youtube_video_id}
              onChange={(event) =>
                setFormData({
                  ...formData,
                  youtube_video_id: extractYoutubeId(event.target.value),
                })
              }
              required
            />
            <Input
              label="Duration"
              placeholder="4:20"
              value={formData.duration}
              onChange={(event) =>
                setFormData({ ...formData, duration: event.target.value })
              }
            />
          </div>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <Input
              label="Speaker"
              value={formData.speaker}
              onChange={(event) =>
                setFormData({ ...formData, speaker: event.target.value })
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
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
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
            label="Custom Thumbnail URL"
            value={formData.thumbnail_url}
            onChange={(event) =>
              setFormData({ ...formData, thumbnail_url: event.target.value })
            }
          />
          <VideoPreview
            youtubeVideoId={formData.youtube_video_id}
            thumbnailUrl={formData.thumbnail_url}
          />
          <TextArea
            label="Description"
            rows={5}
            value={formData.description}
            onChange={(value) =>
              setFormData({ ...formData, description: value })
            }
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
              {editingVideo ? "Update Video" : "Add Video"}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

function VideoThumb({ video }: { video: VideoPost }) {
  const thumbnail = thumbnailFor(video);
  return (
    <div className="relative flex h-16 w-28 shrink-0 items-center justify-center overflow-hidden rounded bg-gray-100">
      {thumbnail ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={thumbnail}
          alt={video.title}
          className="h-full w-full object-cover"
        />
      ) : (
        <Video className="h-6 w-6 text-gray-400" />
      )}
      <div className="absolute inset-0 flex items-center justify-center bg-black/10">
        <PlayCircle className="h-7 w-7 text-white drop-shadow" />
      </div>
    </div>
  );
}

function VideoPreview({
  youtubeVideoId,
  thumbnailUrl,
}: {
  youtubeVideoId: string;
  thumbnailUrl: string;
}) {
  const thumbnail =
    thumbnailUrl ||
    thumbnailFor({
      youtube_video_id: youtubeVideoId,
      thumbnail_url: thumbnailUrl,
    });
  if (!thumbnail) return null;

  return (
    <div>
      <label className="mb-1 block text-sm font-medium text-gray-700">
        Preview
      </label>
      <div className="relative aspect-video w-full overflow-hidden rounded-lg bg-gray-100 md:max-w-md">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={thumbnail} alt="Video preview" className="h-full w-full object-cover" />
        <div className="absolute inset-0 flex items-center justify-center bg-black/10">
          <PlayCircle className="h-12 w-12 text-white drop-shadow" />
        </div>
      </div>
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
      <Video className="mx-auto mb-4 h-12 w-12 text-gray-300" />
      <p>No videos found</p>
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
