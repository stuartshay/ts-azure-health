# TS Azure Health — Frontend Starter (Next.js + BFF + Key Vault + ACA)

Minimal, production-friendly skeleton to:
- Sign-in with Entra ID (MSAL PKCE).
- Call a protected downstream API via a Back-End-for-Front-End (BFF) using On-Behalf-Of (OBO).
- Read a secret from Azure Key Vault using Managed Identity (no secrets in the browser).
- Run locally and deploy as a single container to Azure Container Apps.

## Quick start (local)
1. Install Node 22 (LTS) and `npm ci` in `frontend/`.
2. Copy `frontend/.env.example` to `frontend/.env.local` and fill values.
3. `npm run dev` and open http://localhost:3000

Buttons on the home page:
- **Sign in** → MSAL popup sign-in.
- **Call Protected API** → Sends your SPA token to the BFF, which performs OBO to call your downstream Function/API.
- **Read KV Secret (server)** → BFF uses Default/Managed Identity to read `KV_SECRET_NAME` from Key Vault.

## Deploy to Azure Container Apps (high level)
- Build and push your container image to ACR.
- Deploy `infra/main.bicep` providing:
  - A user-assigned managed identity (UAMI).
  - A Key Vault (grant secret get to the UAMI).
  - Container Apps Environment and a Container App bound to the UAMI.
- Pass non-secret env vars via app settings; BFF loads secrets at runtime from Key Vault.

## Notes
- Keep secrets out of `.env*` files in Git; use Key Vault in cloud.
- You can later remove `AAD_BFF_CLIENT_SECRET` by switching the BFF to a secretless MI OBO variant.
