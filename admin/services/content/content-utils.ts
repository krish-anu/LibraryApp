import type { BlogPost, VideoPost } from "@/lib/types";

export function toNumber(value: unknown, fallback: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function toBoolean(value: unknown, fallback = true) {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    if (value === "true") return true;
    if (value === "false") return false;
  }
  return fallback;
}

export function normalizeBlog(blog: Partial<BlogPost>): BlogPost {
  return {
    id: String(blog.id || ""),
    title: String(blog.title || ""),
    excerpt: String(blog.excerpt || ""),
    content: String(blog.content || ""),
    author: String(blog.author || "Library Team"),
    category: String(blog.category || "Library"),
    cover_image: blog.cover_image || "",
    read_minutes: toNumber(blog.read_minutes, 3),
    published: toBoolean(blog.published, true),
    published_at: String(blog.published_at || new Date().toISOString()),
  };
}

export function normalizeVideo(video: Partial<VideoPost>): VideoPost {
  return {
    id: String(video.id || ""),
    title: String(video.title || ""),
    description: String(video.description || ""),
    youtube_video_id: String(video.youtube_video_id || ""),
    speaker: String(video.speaker || "Library Team"),
    category: String(video.category || "Learning"),
    duration: String(video.duration || ""),
    thumbnail_url: video.thumbnail_url || "",
    published: toBoolean(video.published, true),
    published_at: String(video.published_at || new Date().toISOString()),
  };
}

export function blogPayload(payload: Record<string, unknown>) {
  return {
    title: String(payload.title || ""),
    excerpt: String(payload.excerpt || ""),
    content: String(payload.content || ""),
    author: String(payload.author || "Library Team"),
    category: String(payload.category || "Library"),
    cover_image: String(payload.cover_image || ""),
    read_minutes: toNumber(payload.read_minutes, 3),
    published: toBoolean(payload.published, true),
    published_at: payload.published_at
      ? String(payload.published_at)
      : new Date().toISOString(),
  };
}

export function videoPayload(payload: Record<string, unknown>) {
  return {
    title: String(payload.title || ""),
    description: String(payload.description || ""),
    youtube_video_id: String(payload.youtube_video_id || ""),
    speaker: String(payload.speaker || "Library Team"),
    category: String(payload.category || "Learning"),
    duration: String(payload.duration || ""),
    thumbnail_url: String(payload.thumbnail_url || ""),
    published: toBoolean(payload.published, true),
    published_at: payload.published_at
      ? String(payload.published_at)
      : new Date().toISOString(),
  };
}
