# Infrastructure

This directory contains Infrastructure as Code (IaC) using Azure Bicep templates for the TS Azure Health project.

## Overview

The infrastructure supports multi-environment deployments with environment-specific configurations for:

- **Development (dev)** - For testing and development
- **Staging (staging)** - For pre-production validation (optional)
- **Production (prod)** - For production workloads

Each environment has isolated resources with unique naming to prevent conflicts.

## Files

### Main Templates

- **`main.bicep`** - Main infrastructure template that defines all Azure resources
  - Container Apps Environment
  - Container App
  - Key Vault
  - User-Assigned Managed Identity
  - RBAC role assignments

### Parameter Files

- **`dev.bicepparam`** - Development environment parameters
- **`prod.bicepparam`** - Production environment parameters

These files use the Bicep parameter file format (`.bicepparam`) and reference the main template.

### Modules

- **`modules/acrRoleAssignment.bicep`** - Grants AcrPull role to managed identity on existing ACR

## Resource Naming Convention

Resources are named using the pattern: `{resource-type}-{baseName}-{environment}-{uniqueSuffix}`

**Example for dev environment:**

- Resource Group: `rg-azure-health-dev`
- Container App: `app-tsazurehealth-dev`
- Key Vault: `kv-tsazurehealth-dev-abc123` (with unique suffix)
- Managed Identity: `id-tsazurehealth-dev`
- Container Environment: `env-tsazurehealth-dev`

**Example for prod environment:**

- Resource Group: `rg-azure-health`
- Container App: `app-tsazurehealth-prod`
- Key Vault: `kv-tsazurehealth-prod-xyz789` (with unique suffix)
- Managed Identity: `id-tsazurehealth-prod`
- Container Environment: `env-tsazurehealth-prod`

## Parameters

### Required Parameters

- **`environment`** - Environment name (dev, staging, prod)
  - Default: `dev`
  - Allowed values: `dev`, `staging`, `prod`

### Optional Parameters

- **`location`** - Azure region for resources
  - Default: Resource group location
- **`baseName`** - Base name for resources (will be suffixed with environment)

  - Default: `tsazurehealth`

- **`acrName`** - Name of existing Azure Container Registry

  - Default: `azureconnectedservicesacr`

- **`acrResourceGroup`** - Resource group of the ACR

  - Default: `AzureConnectedServices-RG`

- **`imageTag`** - Container image tag to deploy

  - Default: `latest`

- **`externalIngress`** - Enable public FQDN ingress
  - Default: `true`

## Deployment

### Using Parameter Files

```bash
# Deploy to dev
az deployment group create \
  --resource-group rg-azure-health-dev \
  --template-file main.bicep \
  --parameters dev.bicepparam

# Deploy to prod
az deployment group create \
  --resource-group rg-azure-health \
  --template-file main.bicep \
  --parameters prod.bicepparam
```

### Override Parameters

You can override parameters from the parameter file:

```bash
# Deploy dev with custom image tag
az deployment group create \
  --resource-group rg-azure-health-dev \
  --template-file main.bicep \
  --parameters dev.bicepparam \
  --parameters imageTag=v1.2.3
```

### What-If Preview

Preview changes before deployment:

```bash
az deployment group what-if \
  --resource-group rg-azure-health-dev \
  --template-file main.bicep \
  --parameters dev.bicepparam
```

## Outputs

The deployment provides these outputs:

- **`containerAppName`** - Name of the Container App
- **`containerAppUrl`** - HTTPS URL of the Container App
- **`keyVaultName`** - Name of the Key Vault
- **`keyVaultUrl`** - URL of the Key Vault
- **`managedIdentityName`** - Name of the User-Assigned Managed Identity
- **`managedIdentityPrincipalId`** - Principal ID of the managed identity
- **`resourceGroupName`** - Name of the resource group
- **`environment`** - Environment name (dev, staging, prod)

View outputs after deployment:

```bash
az deployment group show \
  --resource-group rg-azure-health-dev \
  --name <deployment-name> \
  --query properties.outputs
```

## Resources Created

### Container Apps Environment

- Provides hosting environment for Container Apps
- Configured with Log Analytics workspace

### Container App

- Hosts the frontend application
- Pulls images from ACR using managed identity
- Configured with Key Vault URL as environment variable
- External ingress enabled on port 3000
- Auto-scaling configuration (min: 1, max: 1)

### Key Vault

- Stores application secrets
- RBAC authorization enabled
- Managed identity has "Key Vault Secrets User" role

### User-Assigned Managed Identity

- Used by Container App for authentication
- Has "AcrPull" role on ACR (for image pulling)
- Has "Key Vault Secrets User" role on Key Vault

### RBAC Role Assignments

- ACR Pull access for the managed identity
- Key Vault Secrets User access for the managed identity

## Security

### Authentication

- Container App uses User-Assigned Managed Identity
- No credentials stored in code or configuration
- RBAC-based access control throughout

### Secrets Management

- Application secrets stored in Azure Key Vault
- Container App accesses Key Vault using managed identity
- Key Vault URL provided as environment variable

### Network Security

- External ingress can be disabled per environment
- HTTPS enforced for all traffic
- ACR authentication using managed identity

## Tags

All resources are tagged with:

- **`environment`** - Environment name (dev, staging, prod)
- **`project`** - Project name (`ts-azure-health`)
- **`managedBy`** - Deployment method (`bicep`)
- **`createdDate`** - UTC date of creation

## Customization

### Adding a New Environment

1. Create a new parameter file (e.g., `staging.bicepparam`):

   ```bicep
   using './main.bicep'

   param environment = 'staging'
   param baseName = 'tsazurehealth'
   param imageTag = 'latest'
   param externalIngress = true
   ```

2. Update `main.bicep` allowed values for `environment` parameter if needed

3. Deploy using the new parameter file

### Modifying Resources

1. Edit `main.bicep` to add or modify resources
2. Run what-if to preview changes:
   ```bash
   az deployment group what-if \
     --resource-group rg-azure-health-dev \
     --template-file main.bicep \
     --parameters dev.bicepparam
   ```
3. Deploy the changes

## Troubleshooting

### Deployment Failures

View deployment errors:

```bash
az deployment group show \
  --resource-group rg-azure-health-dev \
  --name <deployment-name> \
  --query properties.error
```

### Resource Conflicts

If resources already exist:

- Bicep deployments are idempotent - running again updates existing resources
- Resource names include unique suffix to avoid conflicts
- Each environment has isolated resources

### Permission Issues

Ensure you have:

- Contributor role on the subscription or resource group
- User Access Administrator role (for RBAC assignments)

Check your roles:

```bash
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

## Best Practices

1. **Use Parameter Files** - Keep environment-specific settings in parameter files
2. **Preview Changes** - Always run what-if before deploying to production
3. **Tag Resources** - All resources are automatically tagged with environment and metadata
4. **Managed Identities** - No secrets in code, use managed identities for authentication
5. **RBAC** - Use RBAC instead of access keys for Key Vault and ACR
6. **Isolated Environments** - Keep dev and prod resources completely separate

## Related Documentation

- [Main README](../README.md) - Overall project documentation
- [Scripts README](../scripts/infrastructure/README.md) - Local deployment scripts
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
