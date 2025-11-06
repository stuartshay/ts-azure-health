# TS Azure Health — Frontend Starter (Next.js + BFF + Key Vault + ACA)

Minimal, production-friendly skeleton to:

- Sign-in with Entra ID (MSAL PKCE).
- Call a protected downstream API via a Back-End-for-Front-End (BFF) using On-Behalf-Of (OBO).
- Read a secret from Azure Key Vault using Managed Identity (no secrets in the browser).
- Run locally and deploy as a single container to Azure Container Apps.

## 🚀 Quick Start

**Recommended**: Use VS Code Dev Containers for instant setup with all tools pre-configured!

See the **[Development Setup Guide](docs/DEVELOPMENT_SETUP.md)** for detailed instructions.

### Using Dev Containers (Fastest)

1. Install Docker Desktop and VS Code with Dev Containers extension
2. Clone this repository and open in VS Code
3. Click "Reopen in Container" when prompted
4. Everything is configured and ready to use!

### Manual Setup

If you prefer to set up manually, see [docs/DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md).

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

This project includes automated CI/CD via GitHub Actions for deploying to Azure Container Registry and Azure Container Apps.

### Automated Deployment (Recommended)

#### Prerequisites

1. **Azure Resources**: Create the resource group first:

   ```bash
   az login
   az group create --name rg-azure-health --location eastus
   ```

2. **Azure Service Principal with Federated Credentials**: Create a User-Assigned Managed Identity for GitHub Actions authentication:

   ```bash
   # Create user-assigned managed identity for GitHub Actions
   az identity create \
     --name id-github-actions-ts-azure-health \
     --resource-group rg-azure-health \
     --location eastus

   # Get the client ID and tenant ID
   CLIENT_ID=$(az identity show \
     --name id-github-actions-ts-azure-health \
     --resource-group rg-azure-health \
     --query clientId -o tsv)

   TENANT_ID=$(az account show --query tenantId -o tsv)
   SUBSCRIPTION_ID=$(az account show --query id -o tsv)

   echo "Client ID: $CLIENT_ID"
   echo "Tenant ID: $TENANT_ID"
   echo "Subscription ID: $SUBSCRIPTION_ID"
   ```

3. **Configure Federated Credentials**: Set up OIDC trust for GitHub Actions:

   ```bash
   # For develop branch
   az identity federated-credential create \
     --name github-actions-develop \
     --identity-name id-github-actions-ts-azure-health \
     --resource-group rg-azure-health \
     --issuer https://token.actions.githubusercontent.com \
     --subject repo:stuartshay/ts-azure-health:ref:refs/heads/develop \
     --audiences api://AzureADTokenExchange

   # For master branch (production)
   az identity federated-credential create \
     --name github-actions-master \
     --identity-name id-github-actions-ts-azure-health \
     --resource-group rg-azure-health \
     --issuer https://token.actions.githubusercontent.com \
     --subject repo:stuartshay/ts-azure-health:ref:refs/heads/master \
     --audiences api://AzureADTokenExchange
   ```

4. **Grant Permissions**: Assign necessary roles to the managed identity:

   ```bash
   # Contributor role for deployment
   az role assignment create \
     --assignee $CLIENT_ID \
     --role Contributor \
     --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-azure-health

   # AcrPush role for pushing images
   az role assignment create \
     --assignee $CLIENT_ID \
     --role AcrPush \
     --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-azure-health
   ```

5. **Configure GitHub Secrets**: Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

   | Secret Name             | Value              | Description                |
   | ----------------------- | ------------------ | -------------------------- |
   | `AZURE_CLIENT_ID`       | `$CLIENT_ID`       | Managed identity client ID |
   | `AZURE_TENANT_ID`       | `$TENANT_ID`       | Azure AD tenant ID         |
   | `AZURE_SUBSCRIPTION_ID` | `$SUBSCRIPTION_ID` | Azure subscription ID      |

6. **Run the Workflow**: Go to GitHub Actions → "Deploy Frontend to ACR and Azure Container Apps" → "Run workflow"

   - Select environment: `develop` or `production`
   - Click "Run workflow"

#### Versioning Strategy

The workflow automatically manages versioning based on the environment:

**Production (master branch)**:

- Uses semantic versioning from `frontend/package.json` (e.g., `1.2.3`)
- Tags: `1.2.3`, `1.2`, `1`, `latest`
- Example: `acrtazurehealth.azurecr.io/ts-azure-health-frontend:0.1.0`

**Develop (develop branch)**:

- Uses pre-release versioning with build numbers (e.g., `1.2.3-rc.123`)
- Tags: `1.2.3-rc.123`, `develop`, `sha-abc1234`
- Example: `acrtazurehealth.azurecr.io/ts-azure-health-frontend:0.1.0-rc.42`

To bump the version, update the `version` field in `frontend/package.json` and commit to the respective branch.

#### What the Workflow Does

1. **Build Phase**:

   - Reads version from `frontend/package.json`
   - Generates appropriate tags based on environment
   - Builds Docker image with multi-stage optimization
   - Adds OCI-compliant labels (commit SHA, build date, version)
   - Pushes to Azure Container Registry with multiple tags

2. **Deploy Phase**:
   - Authenticates to Azure using OIDC (federated credentials)
   - Deploys Bicep infrastructure (ACR, Container App, Key Vault, etc.)
   - Updates Container App with new image version
   - Provides deployment summary with application URL

### Manual Deployment (Alternative)

If you prefer to deploy manually or need to troubleshoot:

#### 1. Build and push container image

```bash
# Login to Azure
az login

# Login to ACR
az acr login --name acrtazurehealth

# Build and push
cd frontend/
docker build -t acrtazurehealth.azurecr.io/ts-azure-health-frontend:latest .
docker push acrtazurehealth.azurecr.io/ts-azure-health-frontend:latest
```

#### 2. Deploy infrastructure

Deploy `infrastructure/main.bicep` with required parameters:

```bash
az group create --name rg-azure-health --location eastus

az deployment group create \
  --resource-group rg-azure-health \
  --template-file infrastructure/main.bicep \
  --parameters \
    imageTag="latest" \
    keyVaultName="kv-ts-azure-health-001" \
    containerAppName="app-ts-azure-health" \
    managedEnvName="env-ts-azure-health" \
    uamiName="id-ts-azure-health" \
    acrName="acrtazurehealth"
```

This creates:

- An Azure Container Registry with managed identity authentication
- A user-assigned managed identity (UAMI) with AcrPull and Key Vault access
- A Key Vault with RBAC authorization
- Container Apps Environment
- A Container App with image pull authentication via managed identity
- RBAC role assignments for ACR and Key Vault access

#### 3. Configure environment variables

After deployment, add environment variables to your Container App through the Azure Portal or CLI:

```bash
az containerapp update \
  --name app-ts-azure-health \
  --resource-group rg-azure-health \
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

## Code Quality & Development Tools

This project uses modern development tools to ensure code quality and consistency:

### Pre-commit Hooks

Automated checks run before each commit:

- **Code Linting**: ESLint for TypeScript/JavaScript
- **Type Checking**: TypeScript compiler validation
- **Code Formatting**: Prettier for consistent style
- **File Quality**: Trailing whitespace, end-of-file fixes
- **Syntax Validation**: JSON, YAML checking
- **Security**: Private key detection
- **Docker**: Dockerfile linting with hadolint

Install and use pre-commit hooks:

```bash
pip install pre-commit
pre-commit install
```

See [docs/PRE_COMMIT.md](docs/PRE_COMMIT.md) for detailed information.

### Dev Container

The repository includes a complete development container configuration with:

- All required tools (Node.js, Azure CLI, Docker, Git)
- VS Code extensions for TypeScript, Azure, Docker, and more
- Automatic dependency installation
- Consistent development environment across all machines

See [docs/DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md) for setup instructions.

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
