# Infrastructure Scripts

This folder contains scripts for Azure infrastructure management, deployment, and verification for the TS Azure Health project.

## Available Scripts

### deploy-bicep.sh

**Deploys Azure infrastructure using Bicep template.**

**Usage:**

```bash
# Deploy with defaults (dev environment)
./deploy-bicep.sh

# Deploy to production environment
./deploy-bicep.sh -e prod -l westus2

# Preview changes without deploying
./deploy-bicep.sh -e dev --whatif
```

**Options:**

- `-e, --environment ENV` - Environment: dev, staging, or prod (default: dev)
- `-l, --location LOCATION` - Azure region for deployment (default: eastus)
- `-w, --whatif` - Preview changes without deploying
- `-h, --help` - Display help message

**What it creates:**

- Resource Group with environment tagging
- Azure Container Registry role assignment (AcrPull)
- User-assigned Managed Identity
- Azure Key Vault with RBAC authorization
- Container Apps Environment
- Container App with image pull authentication via managed identity
- RBAC role assignments for ACR and Key Vault access

**Features:**

- Idempotent - safe to run multiple times
- Environment-specific parameter files (dev.bicepparam, prod.bicepparam)
- Comprehensive error handling and validation
- Colored output with progress indicators
- Configures all required resources

**Prerequisites:**

- Azure CLI installed and authenticated (`az login`)
- Appropriate permissions to create resources and assign roles
- jq installed for JSON parsing

### destroy-bicep.sh

**Destroys Azure infrastructure by deleting the resource group.**

**Usage:**

```bash
# Destroy dev environment
./destroy-bicep.sh

# Destroy production environment (requires confirmation)
./destroy-bicep.sh -e prod
```

**Options:**

- `-e, --environment ENV` - Environment: dev, staging, or prod (default: dev)
- `-h, --help` - Display help message

**Features:**

- Lists all resources before deletion
- Requires explicit confirmation
- Colored output showing what will be deleted
- Asynchronous deletion (runs in background)

**Prerequisites:**

- Azure CLI installed and authenticated (`az login`)
- Appropriate permissions to delete resources

**⚠️ WARNING:** This will delete ALL resources in the resource group! This action cannot be undone.

### whatif-bicep.sh

**Previews infrastructure changes using Bicep what-if.**

**Usage:**

```bash
# Preview changes for dev environment
./whatif-bicep.sh

# Preview changes for production environment
./whatif-bicep.sh -e prod -l westus2
```

**Options:**

- `-e, --environment ENV` - Environment: dev, staging, or prod (default: dev)
- `-l, --location LOCATION` - Azure region for deployment (default: eastus)
- `-h, --help` - Display help message

**Features:**

- Shows what would change without deploying
- Creates temporary resource group if needed
- Displays full resource payloads
- No changes are made to Azure resources

**Prerequisites:**

- Azure CLI installed and authenticated (`az login`)
- Reader access to the subscription

## Environment-Specific Deployments

The scripts use environment-specific parameter files located in `infrastructure/`:

- `dev.bicepparam` - Development environment settings
- `prod.bicepparam` - Production environment settings

Each environment creates isolated resources with unique naming:

**Development (dev):**

- Resource Group: `rg-azure-health-dev`
- Container App: `app-tsazurehealth-dev`
- Key Vault: `kv-tsazurehealth-dev-<unique>`
- Managed Identity: `id-tsazurehealth-dev`

**Production (prod):**

- Resource Group: `rg-azure-health`
- Container App: `app-tsazurehealth-prod`
- Key Vault: `kv-tsazurehealth-prod-<unique>`
- Managed Identity: `id-tsazurehealth-prod`

## Common Workflows

### Initial Deployment

```bash
# 1. Preview what will be created
./whatif-bicep.sh -e dev

# 2. Deploy infrastructure
./deploy-bicep.sh -e dev

# 3. Verify deployment in Azure Portal or CLI
az resource list --resource-group rg-azure-health-dev --output table
```

### Update Existing Infrastructure

```bash
# 1. Make changes to main.bicep or parameter files

# 2. Preview the changes
./whatif-bicep.sh -e dev

# 3. Deploy updates
./deploy-bicep.sh -e dev
```

### Cleanup

```bash
# Destroy all resources in an environment
./destroy-bicep.sh -e dev
```

## GitHub Actions Workflows

In addition to these local scripts, the repository includes GitHub Actions workflows for CI/CD:

- `.github/workflows/infrastructure-deploy.yml` - Automated deployment
- `.github/workflows/infrastructure-destroy.yml` - Automated destruction
- `.github/workflows/infrastructure-whatif.yml` - PR preview of changes

These workflows use the same Bicep templates and parameter files as the local scripts.

## Troubleshooting

### Authentication Issues

If you get authentication errors:

```bash
az login
az account show
```

### Permission Errors

Ensure you have the required roles:

```bash
# Check your role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

Required permissions:

- Contributor role on the resource group
- User Access Administrator (for RBAC assignments)

### Parameter File Issues

Ensure parameter files exist:

```bash
ls -la infrastructure/*.bicepparam
```

## Related Documentation

- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
- [Azure Key Vault](https://docs.microsoft.com/azure/key-vault/)
- [Managed Identities](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
