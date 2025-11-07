// TS Azure Health - Bicep Parameters (Development)

using './main.bicep'

param environment = 'dev'
param baseName = 'tsazurehealth'
param imageTag = 'latest'
param externalIngress = true
param acrName = 'azureconnectedservicesacr'
param acrResourceGroup = 'AzureConnectedServices-RG'
