# Figma API Integration Kickoff (ts-azure-health)

We are just getting started.  
This document introduces the setup for integrating the **Figma REST API** into the `ts-azure-health` project.

---

## 🎯 Objective
Set up a minimal, working Figma API client in TypeScript that authenticates using your personal access token.  
This will allow the project to fetch design data, assets, or preview images from Figma when needed.

---

## ⚙️ Step 1 — Generate and Store Token
1. Go to **Figma → Account Settings → Personal Access Tokens**.
2. Click **Create new token** and copy it.
3. In `frontend/.env.local`, add:
   ```bash
   FIGMA_API_TOKEN=<your-token-here>
   FIGMA_FILE_KEY=<optional-default-file-key>
   ```
   Ensure `.env.local` is listed in `.gitignore`.

---

## 📦 Step 2 — Install the SDK
From the project root:
```bash
npm install figma-api
```

---

## 🧩 Step 3 — Create Service File
Create a new file: `frontend/lib/figmaService.ts`

```ts
/*
🤖 Project Kickoff: Figma API Integration for ts-azure-health
-------------------------------------------------------------
We are just getting started.

Goal:
- Establish a minimal, working Figma API client using our personal access token.
- Keep this lightweight and server-side only.
- This will evolve into functions that pull design assets, colors, and images from Figma.

Instructions for GitHub Copilot:
1. Use the "figma-api" npm package (import { Api } from "figma-api").
2. Load environment variables:
   FIGMA_API_TOKEN   -> the personal access token (never expose publicly)
   FIGMA_FILE_KEY    -> the default Figma file key (optional)
3. Export:
   - getFigmaClient(): returns an authenticated Api instance
   - fetchFile(fileKey?: string): retrieves file structure (api.getFile)
   - fetchImages(nodeIds: string[], format?: "png" | "svg"): retrieves rendered image URLs (api.getImages)
4. Include minimal console logging for connection success/errors.
5. Throw clear errors if environment variables are missing.
6. Use async/await and TypeScript typing throughout.

Next Step:
After this file is created, we’ll run a test script in `scripts/testFigma.ts`
to confirm authentication and list basic file info.
*/

export {};
```

---

## 🧪 Step 4 — Verify Setup (optional)
Create `scripts/testFigma.ts` and test your connection.

```ts
import { Api } from "figma-api";

(async () => {
  const token = process.env.FIGMA_API_TOKEN;
  if (!token) {
    console.error("FIGMA_API_TOKEN missing in .env.local");
    process.exit(1);
  }

  const api = new Api({ personalAccessToken: token });
  const fileKey = process.env.FIGMA_FILE_KEY!;
  const file = await api.getFile({ file_key: fileKey });
  console.log("✅ Connected to Figma:", file.name, "Last modified:", file.lastModified);
})();
```

Run:
```bash
npx ts-node scripts/testFigma.ts
```

If you see your Figma file name, the connection works. 🎉

---

## ✅ Next Steps
- Extend `figmaService.ts` with reusable functions for fetching images or design tokens.
- Add caching or rate-limit handling later if needed.
- Keep all Figma logic server-side to protect the token.
