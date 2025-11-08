// TS Azure Health - Bicep Parameters (Staging)

using './main.bicep'

param environment = 'staging'
param baseName = 'tsazurehealth'
param imageTag = 'latest'
param externalIngress = true
param externalIngress = true
// Name of the Azure Container Registry to use for storing and retrieving container images
param acrName = 'azureconnectedservicesacr'
// Resource group where the Azure Container Registry is located
// Resource group where the Azure Container Registry is located
param acrResourceGroup = 'AzureConnectedServices-RG'
