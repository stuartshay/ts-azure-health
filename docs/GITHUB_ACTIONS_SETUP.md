# GitHub Actions CI/CD Setup Guide

This guide explains how to configure GitHub Actions for automated deployment of the Azure Health Frontend to Azure Container Registry and Azure Container Apps.

## Overview

The deployment workflow uses:

- **OIDC Authentication**: Federated credentials for secure, passwordless Azure authentication
- **Semantic Versioning**: Production releases use semver (1.2.3), develop uses pre-release with build numbers (1.2.3-rc.123)
- **Multi-Tag Strategy**: Multiple tags for flexible image management
- **Existing ACR**: Uses existing Azure Container Registry (azureconnectedservicesacr) in AzureConnectedServices-RG
- **Bicep Infrastructure**: Automated deployment of Container Apps, Key Vault, and all dependencies

## Prerequisites

- Azure CLI installed and authenticated
- GitHub repository with admin access
- Azure subscription with Contributor permissions

## Step-by-Step Setup

### 1. Create Azure Resource Group for Shared CI/CD Infrastructure

```bash
az login

# Create dedicated resource group for shared CI/CD infrastructure
# This resource group is permanent and contains the GitHub Actions managed identity
# It should never be deleted as it would break all CI/CD workflows
az group create \
  --name rg-azure-health-shared \
  --location eastus \
  --tags purpose=cicd lifecycle=permanent project=ts-azure-health
```

**Note**: This resource group is separate from environment-specific resource groups (rg-azure-health-dev, rg-azure-health, etc.) to ensure the GitHub Actions identity persists independently of environment lifecycle operations.

### 2. Create User-Assigned Managed Identity for GitHub Actions

This identity will be used by GitHub Actions to authenticate to Azure using OIDC (federated credentials).

**Important**: The managed identity is placed in the shared resource group (not environment-specific groups) to ensure it persists independently. If placed in an environment resource group (e.g., rg-azure-health-dev), destroying that environment would delete the identity and break all GitHub Actions workflows across all environments.

```bash
# Create the managed identity in the shared resource group
az identity create \
  --name id-github-actions-ts-azure-health \
  --resource-group rg-azure-health-shared \
  --location eastus

# Retrieve the credentials (save these for GitHub secrets)
CLIENT_ID=$(az identity show \
  --name id-github-actions-ts-azure-health \
  --resource-group rg-azure-health-shared \
  --query clientId -o tsv)

TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "==============================================="
echo "Save these values for GitHub Secrets:"
echo "==============================================="
echo "AZURE_CLIENT_ID: $CLIENT_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "==============================================="
```

### 3. Configure Federated Credentials for OIDC

Set up trust between GitHub Actions and Azure:

#### For Develop Branch

```bash
az identity federated-credential create \
  --name github-actions-develop \
  --identity-name id-github-actions-ts-azure-health \
  --resource-group rg-azure-health-shared \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:stuartshay/ts-azure-health:ref:refs/heads/develop \
  --audiences api://AzureADTokenExchange
```

#### For Master Branch (Production)

```bash
az identity federated-credential create \
  --name github-actions-master \
  --identity-name id-github-actions-ts-azure-health \
  --resource-group rg-azure-health-shared \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:stuartshay/ts-azure-health:ref:refs/heads/master \
  --audiences api://AzureADTokenExchange
```

#### For Pull Requests

```bash
az identity federated-credential create \
  --name github-actions-pull-request \
  --identity-name id-github-actions-ts-azure-health \
  --resource-group rg-azure-health-shared \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:stuartshay/ts-azure-health:pull_request \
  --audiences api://AzureADTokenExchange
```

**Note**: Replace `stuartshay/ts-azure-health` with your actual GitHub repository path (format: `owner/repo`).

### 4. Grant Azure Permissions

The managed identity needs permissions to deploy infrastructure and push container images:

```bash
# Get the principal ID
PRINCIPAL_ID=$(az identity show \
  --name id-github-actions-ts-azure-health \
  --resource-group rg-azure-health-shared \
  --query principalId -o tsv)

# Contributor role for subscription (allows creating/managing environment resource groups)
az role assignment create \
  --assignee $CLIENT_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# AcrPush role for pushing images to existing ACR
az role assignment create \
  --assignee $CLIENT_ID \
  --role AcrPush \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/AzureConnectedServices-RG/providers/Microsoft.ContainerRegistry/registries/azureconnectedservicesacr
```

### 5. Configure GitHub Repository Secrets

Add the following secrets to your GitHub repository:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each:

| Secret Name             | Value         | Description                |
| ----------------------- | ------------- | -------------------------- |
| `AZURE_CLIENT_ID`       | (from step 2) | Managed identity client ID |
| `AZURE_TENANT_ID`       | (from step 2) | Azure AD tenant ID         |
| `AZURE_SUBSCRIPTION_ID` | (from step 2) | Azure subscription ID      |

### 6. (Optional) Configure GitHub Environments

For additional protection and approval workflows:

1. Go to **Settings** → **Environments**
2. Create two environments:
   - `develop` - Auto-deploy from develop branch
   - `production` - Require manual approval before deploying from master

Configure environment-specific protection rules as needed.

## How to Use the Workflow

### Manual Deployment

1. Go to **Actions** tab in GitHub
2. Select **Deploy Frontend to ACR and Azure Container Apps**
3. Click **Run workflow**
4. Select the target environment:
   - **develop**: Pre-release deployment with build numbers
   - **production**: Stable release deployment
5. Click **Run workflow** button

### Versioning Strategy

The workflow automatically manages versions based on `frontend/package.json`:

#### Production Deployment (master branch)

- **Version Format**: Semantic versioning (e.g., `1.2.3`)
- **Tags Created**:
  - `1.2.3` - Full version
  - `1.2` - Major.minor (for easy patch updates)
  - `1` - Major version
  - `latest` - Latest production release

**Example**:

```
azureconnectedservicesacr.azurecr.io/ts-azure-health-frontend:0.1.0
azureconnectedservicesacr.azurecr.io/ts-azure-health-frontend:0.1
azureconnectedservicesacr.azurecr.io/ts-azure-health-frontend:0
azureconnectedservicesacr.azurecr.io/ts-azure-health-frontend:latest
```

#### Develop Deployment (develop branch)

- **Version Format**: Pre-release with build number (e.g., `1.2.3-rc.123`)
- **Tags Created**:
  - `1.2.3-rc.123` - Versioned pre-release (123 is GitHub run number)
  - `develop` - Latest develop branch build
  - `sha-abc1234` - Specific commit reference

**Example**:

```
azureconnectedservicesacr.azurecr.io/ts-azure-health-frontend:0.1.0-rc.42
azureconnectedservicesacr.azurecr.io/ts-azure-health-frontend:develop
azureconnectedservicesacr.azurecr.io/ts-azure-health-frontend:sha-a1b2c3d
```

### Updating the Version

To release a new version:

1. Update `version` field in `frontend/package.json`:

   ```json
   {
     "version": "0.2.0"
   }
   ```

2. Commit and push to the appropriate branch:

   ```bash
   git add frontend/package.json
   git commit -m "chore: bump version to 0.2.0"
   git push origin develop  # or master
   ```

3. Run the GitHub Actions workflow

## Workflow Details

### Build Job

1. Checks out code
2. Reads version from `frontend/package.json`
3. Generates version tags based on environment
4. Authenticates to Azure via OIDC
5. Builds Docker image with build cache optimization
6. Adds OCI-compliant labels:
   - Version, commit SHA, build date
   - GitHub run ID, actor, ref
   - Source repository URL
7. Pushes image with all tags to ACR
8. Generates SBOM (Software Bill of Materials)
9. Creates build provenance attestation

### Deploy Job

1. Checks out code
2. Authenticates to Azure via OIDC
3. Deploys Bicep template:
   - Azure Container Registry
   - Container Apps Environment
   - Container App with managed identity
   - Key Vault with RBAC
   - Role assignments (AcrPull, Key Vault Secrets User)
4. Retrieves application URL
5. Generates deployment summary

## Security Features

- **OIDC Authentication**: No long-lived credentials stored in GitHub
- **Managed Identity**: Passwordless authentication for Container App
- **RBAC**: Principle of least privilege for all resources
- **No Admin User**: ACR admin account disabled
- **Image Scanning**: SBOM and provenance included
- **Key Vault**: Secrets stored securely, accessed via managed identity

## Troubleshooting

### Federated Credential Issues

If authentication fails:

```bash
# Verify federated credentials exist
az identity federated-credential list \
  --identity-name id-github-actions-ts-azure-health \
  --resource-group rg-azure-health-shared

# Check the subject matches your repository
# Format: repo:OWNER/REPO:ref:refs/heads/BRANCH
```

### Permission Errors

If deployment fails with authorization errors:

```bash
# Verify role assignments
az role assignment list \
  --assignee $CLIENT_ID \
  --all

# Re-assign if needed (subscription scope for creating resource groups)
az role assignment create \
  --assignee $CLIENT_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

### ACR Login Failures

If ACR push fails:

```bash
# Verify ACR exists and identity has AcrPush role
az acr show --name azureconnectedservicesacr --resource-group AzureConnectedServices-RG

# Grant AcrPush role
az role assignment create \
  --assignee $CLIENT_ID \
  --role AcrPush \
  --scope $(az acr show --name azureconnectedservicesacr --query id -o tsv)
```

### Image Pull Errors in Container App

If the Container App can't pull images:

```bash
# Verify the Container App's managed identity has AcrPull
az role assignment list \
  --assignee $(az containerapp show \
    --name app-ts-azure-health \
    --resource-group rg-azure-health \
    --query 'identity.userAssignedIdentities.*.principalId' -o tsv) \
  --all
```

## Best Practices

1. **Version Bumping**: Use conventional commits and consider semantic-release for automated versioning
2. **Testing**: Add automated tests before deployment jobs
3. **Staging**: Use develop environment for testing before production
4. **Monitoring**: Set up Application Insights and alerts
5. **Rollback**: Keep previous image tags for easy rollback
6. **Secrets**: Never commit secrets; use Key Vault references in Container App
7. **Reviews**: Require PR reviews before merging to master
8. **Approvals**: Configure environment protection rules for production

## Additional Resources

- [Azure OIDC with GitHub Actions](https://learn.microsoft.com/azure/developer/github/connect-from-azure)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [GitHub Actions Contexts](https://docs.github.com/actions/learn-github-actions/contexts)
