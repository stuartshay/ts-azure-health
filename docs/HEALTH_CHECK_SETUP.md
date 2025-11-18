# Backend Health Check Feature

## Overview

The health check feature reads the backend Function App URL from Azure Key Vault and checks its health status.

## How It Works

1. When you click **"Read KV Secret (Server)"** button
2. The frontend calls `/api/health-check`
3. The backend:
   - Reads the `function-app-url-dev` secret from Key Vault (`kv-tsazurehealth`)
   - Calls the backend's `/api/health` endpoint
   - Returns health status with metrics

## Setup Requirements

### 1. Azure Key Vault Configuration

You need to configure the following environment variables in `.env.local`:

```bash
# Required: Your Key Vault URL
KV_URL=https://kv-tsazurehealth.vault.azure.net/

# Optional: Secret name (defaults to "function-app-url-dev")
KV_FUNCTION_URL_SECRET_NAME=function-app-url-dev
```

### 2. Azure Authentication

For local development, you need to be authenticated with Azure CLI:

```bash
az login
```

The application uses `DefaultAzureCredential` which will use your Azure CLI credentials locally.

### 3. Key Vault Secret

The Key Vault must contain a secret named `function-app-url-dev` with the backend URL:

```bash
# Add the secret to Key Vault
az keyvault secret set \
  --vault-name kv-tsazurehealth \
  --name function-app-url-dev \
  --value "https://azurehealth-func-dev-4kvoosa2nawya.azurewebsites.net"
```

### 4. Key Vault Permissions

Your Azure account needs the **Key Vault Secrets User** role:

```bash
# Get your user object ID
USER_ID=$(az ad signed-in-user show --query id -o tsv)

# Assign role
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee "$USER_ID" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-azure-health-shared/providers/Microsoft.KeyVault/vaults/kv-tsazurehealth"
```

## Testing

### 1. Test Key Vault Connection

```bash
# Test reading the secret directly
az keyvault secret show \
  --vault-name kv-tsazurehealth \
  --name function-app-url-dev \
  --query value -o tsv
```

### 2. Test Health Check Endpoint

```bash
# Test the API endpoint
curl http://localhost:3000/api/health-check | jq .
```

Expected response:

```json
{
  "success": true,
  "backendUrl": "https://azurehealth-func-dev-4kvoosa2nawya.azurewebsites.net/api/health",
  "status": "Healthy",
  "statusCode": 200,
  "responseTime": 245,
  "timestamp": "2025-11-12T10:30:00.000Z",
  "details": {
    "status": "healthy",
    "version": "1.0.0"
  }
}
```

## UI Display

When healthy:

```
✅ Backend Health Check: Healthy

URL: https://azurehealth-func-dev-4kvoosa2nawya.azurewebsites.net/api/health
Status Code: 200
Response Time: 245ms
Timestamp: 11/12/2025, 10:30:00 AM

Details:
{
  "status": "healthy",
  "version": "1.0.0"
}
```

When unhealthy or unreachable:

```
❌ Backend Health Check: Unreachable

URL: https://azurehealth-func-dev-4kvoosa2nawya.azurewebsites.net/api/health

Error: Health check timeout (5s exceeded)
Timestamp: 11/12/2025, 10:30:00 AM
```

## Troubleshooting

### "KV_URL environment variable not configured"

Add `KV_URL` to your `.env.local` file.

### "Failed to read secret from Key Vault"

1. Check you're logged in: `az account show`
2. Verify you have access: `az keyvault secret show --vault-name kv-tsazurehealth --name function-app-url-dev`
3. Check the Key Vault URL is correct in `.env.local`

### "Health check timeout"

The backend might be:

- Down or unreachable
- Taking longer than 5 seconds to respond
- URL in Key Vault is incorrect

### "Secret 'function-app-url-dev' is empty"

The secret exists but has no value. Update it with:

```bash
az keyvault secret set \
  --vault-name kv-tsazurehealth \
  --name function-app-url-dev \
  --value "https://your-backend-url.azurewebsites.net"
```

## Architecture

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Browser   │────────>│   Frontend   │────────>│  Key Vault   │         │   Backend    │
│             │         │ /api/health- │         │              │         │   Function   │
│  Click Btn  │         │    check     │         │  function-   │         │     App      │
└─────────────┘         │              │────────>│  app-url-dev │────────>│ /api/health  │
                        └──────────────┘         └──────────────┘         └──────────────┘
                                                          │                         │
                                                          │                         │
                                                          ▼                         ▼
                                                   Return URL              Return Health
                                                                              Status
```

## Files

- `/app/api/health-check/route.ts` - Health check API endpoint
- `/app/page.tsx` - Frontend UI with health check button
- `/.env.example` - Environment variables template
- `/.env.local` - Your local configuration (gitignored)
