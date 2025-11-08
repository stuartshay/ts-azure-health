targetScope = 'resourceGroup'

@description('Name of the Key Vault')
param keyVaultName string

@description('Principal ID of the managed identity')
param principalId string

// Reference existing Key Vault in this resource group
resource kv 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

// RBAC: grant "Key Vault Secrets User" role
resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
}

resource kvRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, principalId, roleDef.name)
  scope: kv
  properties: {
    principalId: principalId
    roleDefinitionId: roleDef.id
    principalType: 'ServicePrincipal'
  }
}
