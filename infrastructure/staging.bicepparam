// TS Azure Health - Bicep Parameters (Staging)

using './main.bicep'

param environment = 'staging'
param baseName = 'tsazurehealth'
param imageTag = 'latest'
param externalIngress = true
param acrName = 'azureconnectedservicesacr'
param acrResourceGroup = 'AzureConnectedServices-RG'
