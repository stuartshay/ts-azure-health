// TS Azure Health - Bicep Parameters (Staging)

using './main.bicep'

param environment = 'staging'
param baseName = 'tsazurehealth'
// Name of the Azure Container Registry (ACR) to use for storing and retrieving container images
param acrName = 'azureconnectedservicesacr'
// Resource group where the Azure Container Registry (ACR) is located
param acrResourceGroup = 'AzureConnectedServices-RG'
// Shared Key Vault name (in rg-azure-health-shared)
param sharedKeyVaultName = 'kv-tsazurehealth'
// Shared Key Vault Resource Group name
param sharedKeyVaultResourceGroup = 'rg-azure-health-shared'
