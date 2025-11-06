// TS Azure Health - Bicep Parameters (Production)

using './main.bicep'

param environment = 'prod'
param baseName = 'tsazurehealth'
param imageTag = 'latest'
param externalIngress = true
