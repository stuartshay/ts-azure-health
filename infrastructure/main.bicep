targetScope = 'resourceGroup'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Key Vault name')
param keyVaultName string

@description('Container App name')
param containerAppName string = 'pwsh-health-fe'

@description('Managed Environment name')
param managedEnvName string = 'pwsh-health-fe-env'

@description('User Assigned Managed Identity name')
param uamiName string = 'pwsh-health-fe-uami'

@description('Public FQDN ingress (true = external)')
param externalIngress bool = true

@description('Azure Container Registry name (alphanumeric only)')
param acrName string = 'azureconnectedservicesacr'

@description('Azure Container Registry Resource Group name')
param acrResourceGroup string = 'AzureConnectedServices-RG'

@description('Container image tag version')
param imageTag string = 'latest'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
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
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
    }
  }
}

resource app 'Microsoft.App/containerApps@2025-01-01' = {
  name: containerAppName
  location: location
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
