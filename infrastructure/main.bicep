targetScope = 'resourceGroup'

@description('Environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Base name for resources (will be suffixed with environment)')
param baseName string = 'tsazurehealth'

@description('Azure Container Registry name (alphanumeric only)')
param acrName string = 'azureconnectedservicesacr'

@description('Azure Container Registry Resource Group name')
param acrResourceGroup string = 'AzureConnectedServices-RG'

@description('Shared Key Vault name (in rg-azure-health-shared)')
param sharedKeyVaultName string = 'kv-tsazurehealth'

@description('Shared Key Vault Resource Group name')
param sharedKeyVaultResourceGroup string = 'rg-azure-health-shared'

@description('Current date for tagging (automatically set)')
param currentDate string = utcNow('yyyy-MM-dd')

// Generate unique names based on environment
var managedEnvName = 'env-${baseName}-${environment}'
var uamiName = 'id-${baseName}-${environment}'

// Tags for all resources
var commonTags = {
  environment: environment
  project: 'ts-azure-health'
  managedBy: 'bicep'
  createdDate: currentDate
}

// Log Analytics workspace name
var logAnalyticsWorkspaceName = 'log-${baseName}-${environment}'

// Reference existing shared Key Vault in separate resource group
resource kv 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  scope: resourceGroup(sharedKeyVaultResourceGroup)
  name: sharedKeyVaultName
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: uamiName
  location: location
  tags: commonTags
}

// Log Analytics workspace for Container Apps logs
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Grant UAMI AcrPull role on existing ACR in another resource group
module acrRoleAssignment 'modules/acrRoleAssignment.bicep' = {
  name: 'acrRoleAssignment'
  scope: resourceGroup(acrResourceGroup)
  params: {
    acrName: acrName
    principalId: uami.properties.principalId
  }
}

resource acaEnv 'Microsoft.App/managedEnvironments@2025-07-01' = {
  name: managedEnvName
  location: location
  tags: commonTags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Grant UAMI Key Vault Secrets User role on shared Key Vault
module kvRoleAssignment 'modules/kvRoleAssignment.bicep' = {
  name: 'kvRoleAssignment'
  scope: resourceGroup(sharedKeyVaultResourceGroup)
  params: {
    keyVaultName: sharedKeyVaultName
    principalId: uami.properties.principalId
  }
}

// Outputs
output keyVaultName string = sharedKeyVaultName
output keyVaultUrl string = kv.properties.vaultUri
output managedIdentityName string = uami.name
output managedIdentityPrincipalId string = uami.properties.principalId
output managedEnvironmentId string = acaEnv.id
output managedEnvironmentName string = acaEnv.name
output resourceGroupName string = resourceGroup().name
output environment string = environment
