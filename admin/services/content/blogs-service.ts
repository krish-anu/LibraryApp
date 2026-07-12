import { NextRequest, NextResponse } from "next/server";
import { verifyAdmin } from "@/lib/auth/verify-admin";
import { handleLibraryApiError, libraryApi } from "@/lib/server-api";
import type { BlogPost } from "@/lib/types";
import { blogPayload, normalizeBlog } from "./content-utils";

function matchesBlogSearch(blog: BlogPost, search: string | null) {
  const query = (search || "").trim().toLowerCase();
  if (!query) return true;
  return [blog.title, blog.excerpt, blog.content, blog.author, blog.category].some(
    (value) => String(value || "").toLowerCase().includes(query),
  );
}

function matchesStatus(blog: BlogPost, status: string | null) {
  if (!status) return true;
  if (status === "published") return blog.published;
  if (status === "draft") return !blog.published;
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

    const blogs = await libraryApi<BlogPost[]>(
      request,
      "/blogs?include_unpublished=true",
    );
    const filtered = blogs
      .map(normalizeBlog)
      .filter((blog) => matchesBlogSearch(blog, search))
      .filter((blog) => matchesStatus(blog, status))
      .filter((blog) => !category || blog.category === category);
    const start = Math.max(0, (page - 1) * limit);

    return NextResponse.json({
      data: filtered.slice(start, start + limit),
      totalCount: filtered.length,
    });
  } catch (error) {
    return handleLibraryApiError("Error fetching blogs:", error);
  }
}

export async function POST(request: NextRequest) {
  const auth = await verifyAdmin(request);
  if (auth.error) return auth.error;

  try {
    const createdBlog = await libraryApi<BlogPost>(request, "/blogs", {
      method: "POST",
      body: JSON.stringify(blogPayload((await request.json()) as Record<string, unknown>)),
    });
    return NextResponse.json({ data: normalizeBlog(createdBlog) }, { status: 201 });
  } catch (error) {
    return handleLibraryApiError("Error creating blog:", error);
  }
}
