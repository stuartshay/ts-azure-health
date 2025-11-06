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

@description('Container image tag version')
param imageTag string = 'latest'

@description('Public FQDN ingress (true = external)')
param externalIngress bool = true

@description('Current date for tagging (automatically set)')
param currentDate string = utcNow('yyyy-MM-dd')

// Generate unique names based on environment
var uniqueSuffix = uniqueString(resourceGroup().id)
// Note: Key Vault names are limited to 24 characters and must be globally unique
// The take() function ensures we don't exceed this limit by truncating if needed
// Format: kv-{baseName}-{env}-{unique} where unique is 13 chars from uniqueString()
var keyVaultName = take('kv-${baseName}-${environment}-${uniqueSuffix}', 24)
var containerAppName = 'app-${baseName}-${environment}'
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

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: commonTags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    publicNetworkAccess: 'Enabled'
  }
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
  tags: commonTags
}

// Log Analytics workspace for Container Apps logs
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
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

resource acaEnv 'Microsoft.App/managedEnvironments@2025-01-01' = {
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

resource app 'Microsoft.App/containerApps@2025-01-01' = {
  name: containerAppName
  location: location
  tags: commonTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: acaEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: externalIngress
        targetPort: 3000
      }
      registries: [
        {
          server: acrRoleAssignment.outputs.acrLoginServer
          identity: uami.id
        }
      ]
      secrets: []
      dapr: {
        enabled: false
      }
    }
    template: {
      containers: [
        {
          image: '${acrRoleAssignment.outputs.acrLoginServer}/ts-azure-health-frontend:${imageTag}'
          name: 'frontend'
          env: [
            { name: 'KV_URL', value: kv.properties.vaultUri }
          ]
          probes: []
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

// RBAC: grant the UAMI "Key Vault Secrets User" role on the vault
resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
}

resource kvRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, uami.id, roleDef.name)
  scope: kv
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: roleDef.id
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output containerAppName string = app.name
output containerAppUrl string = 'https://${app.properties.configuration.ingress.fqdn}'
output keyVaultName string = kv.name
output keyVaultUrl string = kv.properties.vaultUri
output managedIdentityName string = uami.name
output managedIdentityPrincipalId string = uami.properties.principalId
output resourceGroupName string = resourceGroup().name
output environment string = environment

