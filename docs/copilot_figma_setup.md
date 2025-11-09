# Figma SDK Setup & Basic Tools — Copilot Instructions (ts-azure-health)

We’re just getting started. This guide gives you **clear, copy‑ready prompts for GitHub Copilot** and the minimal steps to wire up the **Figma REST API** in your TypeScript/Next.js dashboard.

> You already have a token in `.env`. Keep it server‑side only.  
> Acceptable env names in this guide: `FIGMA_API_TOKEN` **or** `FIGMA_API_KEY` (pick one and use it consistently in code).

---

## 0) Prerequisites (Figma side)

**Scopes (read‑only):**
- `current_user:read`
- `file_content:read` (required)
- `file_metadata:read`
- `file_versions:read` (optional)
- `library_content:read` (if reading design system styles/components)

**.env example**
```bash
# ==============================================
# Figma Configuration
# ==============================================
FIGMA_API_TOKEN=figd_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# or, if you prefer:
# FIGMA_API_KEY=figd_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
FIGMA_FILE_KEY=<optional-default-file-key>
```
> Do **not** commit real tokens. Use `.env.local` for local dev.

---

## 1) Install the SDK

From the repo root:
```bash
npm install figma-api
```

If you prefer zero deps, you can skip the SDK and use native `fetch` — the prompts below work either way.

---

## 2) Create a reusable client — `frontend/lib/figmaService.ts`

Paste the prompt **as the only content** of a new file to steer Copilot:

```ts
/*
🎯 GOAL
Create a minimal, server‑only Figma client for ts-azure-health.

REQUIREMENTS
- Use TypeScript.
- Prefer the "figma-api" package (import { Api } from "figma-api").
  Fallback: native fetch if the package is unavailable.
- Read the token from process.env.FIGMA_API_TOKEN or process.env.FIGMA_API_KEY.
- Never expose the token to the browser.

EXPORT THE FOLLOWING:
1) getFigmaClient(): Api
   - Validates env var exists, throws a descriptive error if missing.
   - Returns an authenticated client instance.

2) fetchFile(fileKey?: string): Promise<any>
   - Uses default from process.env.FIGMA_FILE_KEY if fileKey not provided.
   - Calls api.getFile({ file_key }) and returns JSON.

3) fetchImages(nodeIds: string[], format?: "png" | "svg" | "jpg"): Promise<Record<string,string>>
   - Calls api.getImages({ file_key }, { ids: nodeIds.join(","), format })
   - Returns the images map (nodeId -> image URL).

LOGGING & TYPES
- Add small console.debug logs (guarded) to help diagnose issues.
- Strong typing where feasible; otherwise type as unknown and narrow.
*/
```

> After Copilot generates code, ensure the import path is `@/lib/figmaService` when used inside `frontend`.

---

## 3) Quick connectivity test — `scripts/testFigma.ts`

Create the file and paste this prompt to generate a tiny smoke test:

```ts
/*
Write a TypeScript script that:
1) Imports { Api } from "figma-api".
2) Reads token from FIGMA_API_TOKEN or FIGMA_API_KEY; exits with a clear message if missing.
3) If FIGMA_FILE_KEY is set, calls api.getFile({ file_key }) and logs the file name + last modified.
   Otherwise calls api.getMe() and logs the authenticated user handle/email.
4) Use top-level await or an IIFE; proper try/catch with non-zero exit on error.
*/
```

Run it:
```bash
npx ts-node scripts/testFigma.ts
```

Expected output (example):
```
🔑 Token OK
✅ Connected to Figma file: Corp IT Dashboard • lastModified: 2025-11-08T12:34:56Z
```

---

## 4) Optional: API route for previews — `frontend/app/api/figma/preview/route.ts`

Prompt for Copilot:
```ts
/*
Create a Next.js App Router API route that:
- Uses fetchImages(fileKey, [nodeId], "png") from "@/lib/figmaService".
- Reads ?nodeId= and optional ?fileKey= from the URL.
- Returns a 302 redirect to the Figma CDN image URL, or 404 on miss.
- Handles errors with a JSON body { error } and appropriate status.
Note: This code must run server-side only.
*/
```

Usage in a component:
```tsx
<img src={"/api/figma/preview?nodeId=123:456"} alt="Figma preview" />
```

---

## 5) Safety & Tips

- Keep all Figma calls **server-side** (API routes, server components, build scripts).
- Figma image URLs expire (≈30 days). Fetch on demand or add caching.
- Rate limits apply; batch node IDs when exporting images.
- For AI that **edits** designs, build a **Figma Plugin** (Plugin API). REST tokens can’t modify canvas.

---

## 6) Next steps you can ask Copilot for

- “Add a function to list component names and IDs from the default file.”  
- “Add a function to traverse styles and print color variables.”  
- “Create a build script that exports all icon components as SVGs into /public/icons.”  
- “Add basic memoization to figmaService to avoid repeated calls.”

---

**You’re set.** With the SDK installed, env configured, and these prompts, Copilot will scaffold the client and test in minutes.
