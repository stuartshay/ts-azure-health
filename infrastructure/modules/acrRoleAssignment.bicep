targetScope = 'resourceGroup'

@description('ACR resource name')
param acrName string

@description('Managed Identity Principal ID')
param principalId string

// Reference the ACR in this resource group
resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' existing = {
  name: acrName
}

// Grant AcrPull role
resource acrPullRoleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, acrPullRoleDef.name)
  scope: acr
  properties: {
    principalId: principalId
    roleDefinitionId: acrPullRoleDef.id
    principalType: 'ServicePrincipal'
  }
}

output acrLoginServer string = acr.properties.loginServer
