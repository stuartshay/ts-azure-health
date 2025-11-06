# TS Azure Health — Frontend Starter (Next.js + BFF + Key Vault + ACA)

Minimal, production-friendly skeleton to:
- Sign-in with Entra ID (MSAL PKCE).
- Call a protected downstream API via a Back-End-for-Front-End (BFF) using On-Behalf-Of (OBO).
- Read a secret from Azure Key Vault using Managed Identity (no secrets in the browser).
- Run locally and deploy as a single container to Azure Container Apps.

## Prerequisites

- Node.js 22 (LTS)
- Azure subscription
- Azure CLI (for deployment)
- Two Azure AD App Registrations:
  - One for the SPA (Single Page Application)
  - One for the BFF (Backend-for-Frontend)

## Quick start (local)

1. Install Node 22 (LTS) and dependencies:
   ```bash
   cd frontend/
   npm install
   ```

2. Copy `frontend/.env.example` to `frontend/.env.local` and fill in your Azure values:
   ```bash
   cp .env.example .env.local
   ```
   
   You'll need to configure:
   - `NEXT_PUBLIC_AAD_CLIENT_ID` - Your SPA app registration client ID
   - `NEXT_PUBLIC_AAD_TENANT_ID` - Your Azure tenant ID
   - `AAD_BFF_CLIENT_ID` - Your BFF app registration client ID
   - `AAD_BFF_CLIENT_SECRET` - Your BFF app registration client secret
   - `DOWNSTREAM_API_URL` - The URL of your protected API
   - `KV_URL` - Your Azure Key Vault URL
   - Other environment variables as needed

3. Start the development server:
   ```bash
   npm run dev
   ```
   
4. Open http://localhost:3000

## Features & UI

Buttons on the home page:
- **Sign in** → MSAL popup sign-in with Entra ID (Azure AD).
- **Call Protected API** → Sends your SPA token to the BFF, which performs OBO to call your downstream Function/API.
- **Read KV Secret (server)** → BFF uses DefaultAzureCredential/Managed Identity to read `KV_SECRET_NAME` from Key Vault.

## Project Structure

```
frontend/
├── app/
│   ├── api/
│   │   ├── call-downstream/    # BFF endpoint for OBO flow
│   │   │   └── route.ts
│   │   └── kv-secret/          # BFF endpoint for Key Vault access
│   │       └── route.ts
│   ├── layout.tsx              # Root layout
│   └── page.tsx                # Home page with demo buttons
├── lib/
│   └── msalClient.ts           # MSAL browser client configuration
├── .env.example                # Environment variables template
├── Dockerfile                  # Multi-stage Docker build
├── next.config.ts              # Next.js configuration
├── package.json                # Dependencies and scripts
└── tsconfig.json               # TypeScript configuration

infrastructure/
└── main.bicep                  # Azure infrastructure as code
```

## Building and Testing

### Build the project
```bash
cd frontend/
npm run build
```

### Lint the code
```bash
npm run lint
```

### Build Docker container locally
```bash
cd frontend/
docker build -t ts-azure-health-frontend:latest .
```

## Deploy to Azure Container Apps

### 1. Build and push container image

```bash
# Login to Azure
az login

# Create or use existing ACR
ACR_NAME="myacr"
az acr login --name $ACR_NAME

# Build and push
cd frontend/
docker build -t ${ACR_NAME}.azurecr.io/ts-azure-health-frontend:latest .
docker push ${ACR_NAME}.azurecr.io/ts-azure-health-frontend:latest
```

### 2. Deploy infrastructure

Deploy `infrastructure/main.bicep` with required parameters:

```bash
az group create --name rg-ts-azure-health --location eastus

az deployment group create \
  --resource-group rg-ts-azure-health \
  --template-file infrastructure/main.bicep \
  --parameters \
    containerImage="${ACR_NAME}.azurecr.io/ts-azure-health-frontend:latest" \
    keyVaultName="kv-ts-azure-health-001" \
    containerAppName="app-ts-azure-health" \
    managedEnvName="env-ts-azure-health" \
    uamiName="id-ts-azure-health"
```

This creates:
- A user-assigned managed identity (UAMI)
- A Key Vault with RBAC authorization
- Container Apps Environment
- A Container App bound to the UAMI with appropriate permissions
- RBAC role assignment granting the UAMI "Key Vault Secrets User" access

### 3. Configure environment variables

After deployment, add environment variables to your Container App through the Azure Portal or CLI:

```bash
az containerapp update \
  --name app-ts-azure-health \
  --resource-group rg-ts-azure-health \
  --set-env-vars \
    "NEXT_PUBLIC_AAD_CLIENT_ID=<your-spa-client-id>" \
    "NEXT_PUBLIC_AAD_TENANT_ID=<your-tenant-id>" \
    "AAD_BFF_CLIENT_ID=<your-bff-client-id>" \
    "AAD_BFF_CLIENT_SECRET=secretref:<secret-name>" \
    "AAD_TENANT_ID=<your-tenant-id>" \
    "KV_SECRET_NAME=<your-secret-name>"
```

## Security Notes

- **Keep secrets out of `.env*` files in Git** - Use Azure Key Vault in production.
- The `.env.example` file is safe to commit and shows required configuration.
- Never commit `.env.local` or `.env` files containing real secrets.
- You can remove `AAD_BFF_CLIENT_SECRET` by switching the BFF to use a certificate or secretless Managed Identity OBO variant.
- The application uses Managed Identity in Azure to access Key Vault without storing credentials.

## Technology Stack

- **Frontend Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Authentication**: MSAL (Microsoft Authentication Library)
  - `@azure/msal-browser` for client-side auth
  - `@azure/msal-node` for server-side OBO flow
- **Azure SDK**:
  - `@azure/identity` for authentication
  - `@azure/keyvault-secrets` for Key Vault access
- **Runtime**: Node.js 22
- **Deployment**: Azure Container Apps

## Troubleshooting

### Build fails with "No root layout" error
Make sure `frontend/app/layout.tsx` exists. This file was added as part of the implementation.

### MSAL authentication errors
- Verify your app registrations in Azure AD
- Check that redirect URIs are configured correctly
- Ensure the API scopes are properly exposed and granted

### Key Vault access denied
- Verify the managed identity has "Key Vault Secrets User" role
- Check that the Key Vault URL and secret name are correct
- Ensure the Container App is using the correct managed identity

## License

This is a starter template for educational and development purposes.

