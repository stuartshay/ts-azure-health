/*
 * Figma Preview API Route
 *
 * Server-side endpoint for fetching Figma node images and redirecting to CDN URLs.
 * This keeps the Figma API token secure on the server while allowing
 * frontend components to display Figma assets.
 *
 * Usage:
 *   <img src="/api/figma/preview?nodeId=123:456" alt="Design preview" />
 *   <img src="/api/figma/preview?nodeId=123:456&fileKey=ABC123xyz&format=svg" />
 *
 * Query Parameters:
 * - nodeId (required): Figma node ID to export
 * - fileKey (optional): Figma file key (uses FIGMA_FILE_KEY env if not provided)
 * - format (optional): Image format - png, svg, or jpg (default: png)
 * - scale (optional): Scale multiplier (default: 1)
 *
 * Response:
 * - 302 redirect to Figma CDN image URL
 * - 400 if nodeId is missing or invalid
 * - 404 if image cannot be generated
 * - 500 for server errors
 */

import { NextRequest, NextResponse } from "next/server";
import { fetchImage } from "@/lib/figmaService";

// Cache-Control header for client-side caching (24 hours)
// Figma image URLs are stable for ~30 days
const CACHE_HEADERS = {
  "Cache-Control": "public, max-age=86400, s-maxage=86400, stale-while-revalidate=604800",
};

/**
 * GET /api/figma/preview
 *
 * Fetches a Figma node image URL and redirects to it.
 * Uses server-side caching to minimize API calls.
 */
export async function GET(request: NextRequest) {
  try {
    // Parse query parameters
    const { searchParams } = new URL(request.url);
    const nodeId = searchParams.get("nodeId");
    const fileKey = searchParams.get("fileKey") || undefined;
    const format = (searchParams.get("format") as "png" | "svg" | "jpg") || "png";
    const scaleParam = searchParams.get("scale");
    const scale = scaleParam ? parseFloat(scaleParam) : 1;

    // Validate required parameters
    if (!nodeId) {
      return NextResponse.json(
        {
          error: "Missing required parameter: nodeId",
          usage: "/api/figma/preview?nodeId=123:456&fileKey=ABC123xyz&format=png&scale=2",
        },
        { status: 400 }
      );
    }

    // Validate format
    if (!["png", "svg", "jpg"].includes(format)) {
      return NextResponse.json(
        {
          error: "Invalid format. Must be: png, svg, or jpg",
        },
        { status: 400 }
      );
    }

    // Validate scale
    if (isNaN(scale) || scale <= 0 || scale > 4) {
      return NextResponse.json(
        {
          error: "Invalid scale. Must be a number between 0 and 4",
        },
        { status: 400 }
      );
    }

    // Fetch image URL from Figma API (with caching)
    const imageUrl = await fetchImage(nodeId, {
      fileKey,
      format,
      scale,
    });

    if (!imageUrl) {
      return NextResponse.json(
        {
          error: "Image not found",
          details: "Figma API did not return an image URL for the specified node",
          nodeId,
          fileKey: fileKey || process.env.FIGMA_FILE_KEY || "not-set",
        },
        { status: 404 }
      );
    }

    // Redirect to Figma CDN with cache headers
    return NextResponse.redirect(imageUrl, {
      status: 302,
      headers: CACHE_HEADERS,
    });
  } catch (error: any) {
    console.error("[Figma Preview API] Error:", error);

    // Handle common error cases
    if (error.message?.includes("FIGMA_API_TOKEN")) {
      return NextResponse.json(
        {
          error: "Server configuration error",
          details: "Figma API token not configured",
        },
        { status: 500 }
      );
    }

    if (error.message?.includes("FIGMA_FILE_KEY")) {
      return NextResponse.json(
        {
          error: "Missing file key",
          details: "No fileKey provided and FIGMA_FILE_KEY environment variable not set",
        },
        { status: 400 }
      );
    }

    if (error.response?.status === 403) {
      return NextResponse.json(
        {
          error: "Access denied",
          details: "Figma API token does not have permission to access this file",
        },
        { status: 403 }
      );
    }

    if (error.response?.status === 404) {
      return NextResponse.json(
        {
          error: "File or node not found",
          details: "The specified file or node does not exist or is not accessible",
        },
        { status: 404 }
      );
    }

    if (error.response?.status === 429) {
      return NextResponse.json(
        {
          error: "Rate limit exceeded",
          details: "Too many requests to Figma API. Please try again later.",
        },
        {
          status: 429,
          headers: {
            "Retry-After": "60",
          },
        }
      );
    }

    // Generic error response
    return NextResponse.json(
      {
        error: "Failed to fetch image",
        details: error.message || "Unknown error",
      },
      { status: 500 }
    );
  }
}
