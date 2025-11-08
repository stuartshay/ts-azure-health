// TS Azure Health - Bicep Parameters (Production)

using './main.bicep'

param environment = 'prod'
param baseName = 'tsazurehealth'
param imageTag = 'latest'
param externalIngress = true
// Name of the Azure Container Registry (ACR) to pull container images from.
param acrName = 'azureconnectedservicesacr'
// Resource group where the Azure Container Registry (ACR) is located.
param acrResourceGroup = 'AzureConnectedServices-RG'
