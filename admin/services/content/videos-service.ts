import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";
import type { VideoPost } from "@/lib/types";
import { normalizeVideo, videoPayload } from "./content-utils";

function matchesVideoSearch(video: VideoPost, search: string | null) {
  const query = (search || "").trim().toLowerCase();
  if (!query) return true;
  return [
    video.title,
    video.description,
    video.speaker,
    video.category,
    video.youtube_video_id,
  ].some((value) => String(value || "").toLowerCase().includes(query));
}

function matchesStatus(video: VideoPost, status: string | null) {
  if (!status) return true;
  if (status === "published") return video.published;
  if (status === "draft") return !video.published;
  return true;
}

export async function GET(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get("page") || "1");
    const limit = parseInt(searchParams.get("limit") || "10");
    const search = searchParams.get("search");
    const status = searchParams.get("status");
    const category = searchParams.get("category");

    const videos = await libraryApi<VideoPost[]>(
      request,
      "/videos?include_unpublished=true",
    );
    const filtered = videos
      .map(normalizeVideo)
      .filter((video) => matchesVideoSearch(video, search))
      .filter((video) => matchesStatus(video, status))
      .filter((video) => !category || video.category === category);
    const start = Math.max(0, (page - 1) * limit);

    return NextResponse.json({
      data: filtered.slice(start, start + limit),
      totalCount: filtered.length,
    });
  } catch (error) {
    return handleLibraryApiError("Error fetching videos:", error);
  }
}

export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const createdVideo = await libraryApi<VideoPost>(request, "/videos", {
      method: "POST",
      body: JSON.stringify(videoPayload((await request.json()) as Record<string, unknown>)),
    });
    return NextResponse.json({ data: normalizeVideo(createdVideo) }, { status: 201 });
  } catch (error) {
    return handleLibraryApiError("Error creating video:", error);
  }
}
