/*
 * Figma Service — Server-side only
 *
 * Provides authenticated access to the Figma REST API with built-in caching
 * to stay within free-tier rate limits (60 requests/minute).
 *
 * Features:
 * - In-memory LRU cache (max 50 items, 30-minute TTL)
 * - Automatic token validation
 * - Type-safe API responses
 * - Development mode logging for cache diagnostics
 *
 * Environment Variables (required):
 * - FIGMA_API_TOKEN: Personal access token from Figma
 * - FIGMA_FILE_KEY: (optional) Default file key for operations
 */

import { Api } from "figma-api";

// ============================================================================
// Types
// ============================================================================

interface CacheEntry<T> {
  data: T;
  timestamp: number;
}

interface CacheStats {
  hits: number;
  misses: number;
  size: number;
  maxSize: number;
  ttlMinutes: number;
}

// ============================================================================
// Configuration
// ============================================================================

const CACHE_MAX_SIZE = 50; // Maximum number of cached items
const CACHE_TTL_MS = 30 * 60 * 1000; // 30 minutes
const isDevelopment = process.env.NODE_ENV === "development";

// ============================================================================
// Cache Implementation
// ============================================================================

class FigmaCache {
  private cache = new Map<string, CacheEntry<unknown>>();
  private stats = {
    hits: 0,
    misses: 0,
  };

  /**
   * Get cached data if valid, otherwise return null
   */
  get<T>(key: string): T | null {
    const entry = this.cache.get(key);

    if (!entry) {
      this.stats.misses++;
      if (isDevelopment) {
        console.debug(`[Figma Cache] MISS: ${key}`);
      }
      return null;
    }

    // Check if entry has expired
    const age = Date.now() - entry.timestamp;
    if (age > CACHE_TTL_MS) {
      this.cache.delete(key);
      this.stats.misses++;
      if (isDevelopment) {
        console.debug(`[Figma Cache] EXPIRED: ${key} (age: ${Math.round(age / 1000)}s)`);
      }
      return null;
    }

    this.stats.hits++;
    if (isDevelopment) {
      console.debug(`[Figma Cache] HIT: ${key} (age: ${Math.round(age / 1000)}s)`);
    }
    return entry.data as T;
  }

  /**
   * Store data in cache with LRU eviction
   */
  set<T>(key: string, data: T): void {
    // Implement LRU: if cache is full, remove oldest entry
    if (this.cache.size >= CACHE_MAX_SIZE && !this.cache.has(key)) {
      const firstKey = this.cache.keys().next().value;
      if (firstKey) {
        this.cache.delete(firstKey);
        if (isDevelopment) {
          console.debug(`[Figma Cache] EVICT: ${firstKey} (LRU)`);
        }
      }
    }

    this.cache.set(key, {
      data,
      timestamp: Date.now(),
    });

    if (isDevelopment) {
      console.debug(`[Figma Cache] SET: ${key} (size: ${this.cache.size}/${CACHE_MAX_SIZE})`);
    }
  }

  /**
   * Clear all cached data
   */
  clear(): void {
    const previousSize = this.cache.size;
    this.cache.clear();
    this.stats.hits = 0;
    this.stats.misses = 0;
    if (isDevelopment) {
      console.debug(`[Figma Cache] CLEAR: Removed ${previousSize} entries`);
    }
  }

  /**
   * Get cache statistics
   */
  getStats(): CacheStats {
    return {
      hits: this.stats.hits,
      misses: this.stats.misses,
      size: this.cache.size,
      maxSize: CACHE_MAX_SIZE,
      ttlMinutes: CACHE_TTL_MS / 60000,
    };
  }
}

// Singleton cache instance
const cache = new FigmaCache();

// ============================================================================
// Client Management
// ============================================================================

let clientInstance: Api | null = null;

/**
 * Get or create authenticated Figma API client
 *
 * @throws Error if FIGMA_API_TOKEN is not configured
 * @returns Authenticated Figma API client instance
 */
export function getFigmaClient(): Api {
  if (clientInstance) {
    return clientInstance;
  }

  const token = process.env.FIGMA_API_TOKEN || process.env.FIGMA_API_KEY;

  if (!token) {
    throw new Error(
      "Figma API token not found. Please set FIGMA_API_TOKEN environment variable.\n" +
        "Generate a token at: https://www.figma.com/developers/api#access-tokens"
    );
  }

  if (!token.startsWith("figd_")) {
    console.warn(
      "[Figma Service] Warning: Token does not start with 'figd_'. " +
        "Ensure you're using a valid Personal Access Token."
    );
  }

  clientInstance = new Api({ personalAccessToken: token });

  if (isDevelopment) {
    console.debug("[Figma Service] Client initialized with token");
  }

  return clientInstance;
}

/**
 * Get the default file key from environment or throw error
 */
function getDefaultFileKey(): string {
  const fileKey = process.env.FIGMA_FILE_KEY;
  if (!fileKey) {
    throw new Error(
      "No file key provided and FIGMA_FILE_KEY environment variable is not set.\n" +
        "Either pass a fileKey parameter or set FIGMA_FILE_KEY in your environment."
    );
  }
  return fileKey;
}

// ============================================================================
// API Methods with Caching
// ============================================================================

/**
 * Fetch a Figma file by key with caching
 *
 * @param fileKey - Figma file key (optional if FIGMA_FILE_KEY is set)
 * @returns Promise resolving to Figma file data
 * @throws Error if file key is not provided or API call fails
 */
export async function fetchFile(fileKey?: string): Promise<any> {
  const key = fileKey || getDefaultFileKey();
  const cacheKey = `file:${key}`;

  // Check cache first
  const cached = cache.get(cacheKey);
  if (cached) {
    return cached;
  }

  // Fetch from API
  if (isDevelopment) {
    console.debug(`[Figma Service] Fetching file: ${key}`);
  }

  try {
    const api = getFigmaClient();
    const response = await api.getFile({ file_key: key });

    // Cache the response
    cache.set(cacheKey, response);

    return response;
  } catch (error) {
    console.error(`[Figma Service] Error fetching file ${key}:`, error);
    throw error;
  }
}

/**
 * Fetch image URLs for specific nodes with caching
 *
 * @param nodeIds - Array of node IDs to export
 * @param options - Export options (fileKey, format, scale, etc.)
 * @returns Promise resolving to map of node IDs to image URLs
 * @throws Error if required parameters are missing or API call fails
 */
export async function fetchImages(
  nodeIds: string[],
  options?: {
    fileKey?: string;
    format?: "png" | "svg" | "jpg";
    scale?: number;
  }
): Promise<Record<string, string | null>> {
  if (!nodeIds || nodeIds.length === 0) {
    throw new Error("nodeIds array is required and cannot be empty");
  }

  const fileKey = options?.fileKey || getDefaultFileKey();
  const format = options?.format || "png";
  const scale = options?.scale || 1;

  const cacheKey = `images:${fileKey}:${nodeIds.join(",")}:${format}:${scale}`;

  // Check cache first
  const cached = cache.get<Record<string, string | null>>(cacheKey);
  if (cached) {
    return cached;
  }

  // Fetch from API
  if (isDevelopment) {
    console.debug(
      `[Figma Service] Fetching images: ${nodeIds.length} nodes, format=${format}, scale=${scale}`
    );
  }

  try {
    const api = getFigmaClient();
    const response = await api.getImages(
      { file_key: fileKey },
      {
        ids: nodeIds.join(","),
        format,
        scale,
      }
    );

    if (!response.images) {
      throw new Error("No images returned from Figma API");
    }

    // Cache the response
    cache.set(cacheKey, response.images);

    return response.images;
  } catch (error) {
    console.error(`[Figma Service] Error fetching images:`, error);
    throw error;
  }
}

/**
 * Fetch image URL for a single node with caching (convenience wrapper)
 *
 * @param nodeId - Single node ID to export
 * @param options - Export options (fileKey, format, scale, etc.)
 * @returns Promise resolving to the image URL (or null if not found)
 * @throws Error if required parameters are missing or API call fails
 */
export async function fetchImage(
  nodeId: string,
  options?: {
    fileKey?: string;
    format?: "png" | "svg" | "jpg";
    scale?: number;
  }
): Promise<string | null> {
  const images = await fetchImages([nodeId], options);
  return images[nodeId] ?? null;
}

/**
 * Clear all cached Figma data
 *
 * Useful for testing or when you need fresh data from the API
 */
export function clearCache(): void {
  cache.clear();
}

/**
 * Get cache statistics for monitoring
 *
 * @returns Cache hit/miss stats and current size
 */
export function getCacheStats(): CacheStats {
  return cache.getStats();
}
