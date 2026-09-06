targetScope = 'resourceGroup'

@description('Azure region used by the existing ShareCloud backend resources.')
param location string = 'francecentral'

@description('Microsoft Entra tenant ID. Defaults to the deployment tenant.')
param tenantId string = tenant().tenantId

@description('Resource names. Defaults match the adopted ShareCloud environment.')
param names object = {
  virtualNetwork: 'sharecloud-vnet'
  subnet: 'default'
  logAnalytics: 'sharecloud-log-workspace'
  applicationInsights: 'sharecloud-app-insights'
  storageAccount: 'sharecloudstorage'
  cosmosAccount: 'sharecloud-cosmos-db'
  keyVault: 'sharecloud-kv'
  searchService: 'sharecloud-ai-search'
  foundryAccount: 'sharecloud-foundry-instance'
  foundryProject: 'proj-default'
  modelDeployment: 'gpt-5-mini'
}

@description('Tags applied to resources that currently have no resource-specific tag set.')
param tags object = {}

@description('Tags preserved on the adopted Cosmos DB account.')
param cosmosTags object = {
  defaultExperience: 'Core (SQL)'
  'hidden-cosmos-mmspecial': ''
  'hidden-workload-type': 'Development/Testing'
}

@description('Virtual network address space.')
param vnetAddressPrefixes array = [
  '10.0.0.0/16'
]

@description('Default subnet address space.')
param subnetAddressPrefixes array = [
  '10.0.0.0/24'
]

@description('Current Foundry account IP allow-list. Review before any deployment because these values may represent temporary administrator addresses.')
param foundryAllowedIpRanges array = [
  '134.238.51.37'
  '148.252.133.168'
]

@description('Current Cosmos DB IP allow-list. Review before any deployment because these values may include Azure service or temporary administrator addresses.')
param cosmosAllowedIpRanges array = [
  '0.0.0.0'
  '134.238.51.37'
  '148.252.141.60'
  '148.252.128.142'
  '4.210.172.107'
  '13.88.56.148'
  '13.91.105.215'
  '40.91.218.243'
]

@description('Whether the non-secret project connections should be managed. Disabled for the first adoption deployment; enable only after a clean what-if.')
param manageProjectConnections bool = false

@description('Whether to preserve the legacy Key Vault access policy for the Foundry account managed identity while RBAC adoption is checked.')
param preserveLegacyKeyVaultAccessPolicy bool = true

@description('Model version currently deployed in the Foundry account.')
param modelVersion string = '2025-08-07'

@description('Model deployment SKU.')
param modelSkuName string = 'GlobalStandard'

@description('Model deployment capacity.')
param modelCapacity int = 500

module networking './modules/networking.bicep' = {
  name: 'networking'
  params: {
    location: location
    tags: tags
    virtualNetworkName: names.virtualNetwork
    subnetName: names.subnet
    vnetAddressPrefixes: vnetAddressPrefixes
    subnetAddressPrefixes: subnetAddressPrefixes
  }
}

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    logAnalyticsName: names.logAnalytics
    applicationInsightsName: names.applicationInsights
  }
}

module storage './modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    tags: tags
    storageAccountName: names.storageAccount
    subnetId: networking.outputs.subnetId
  }
}

module cosmos './modules/cosmos.bicep' = {
  name: 'cosmos'
  params: {
    location: location
    tags: cosmosTags
    cosmosAccountName: names.cosmosAccount
    subnetId: networking.outputs.subnetId
    allowedIpRanges: cosmosAllowedIpRanges
  }
}

module search './modules/search.bicep' = {
  name: 'search'
  params: {
    location: location
    tags: tags
    searchServiceName: names.searchService
  }
}

module foundry './modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    location: location
    tags: tags
    foundryAccountName: names.foundryAccount
    foundryProjectName: names.foundryProject
    modelDeploymentName: names.modelDeployment
    modelVersion: modelVersion
    modelSkuName: modelSkuName
    modelCapacity: modelCapacity
    subnetId: networking.outputs.subnetId
    allowedIpRanges: foundryAllowedIpRanges
  }
}

module keyVault './modules/key-vault.bicep' = {
  name: 'key-vault'
  params: {
    location: location
    tags: tags
    tenantId: tenantId
    keyVaultName: names.keyVault
    subnetId: networking.outputs.subnetId
    foundryPrincipalId: foundry.outputs.foundryPrincipalId
    preserveLegacyAccessPolicy: preserveLegacyKeyVaultAccessPolicy
  }
}

// Project connections are intentionally adoption-gated. The App Insights API-key
// connection is not recreated because its credential was redacted from the snapshot.
module projectConnections './modules/project-connections.bicep' = if (manageProjectConnections) {
  name: 'project-connections'
  params: {
    foundryAccountName: names.foundryAccount
    foundryProjectName: names.foundryProject
    keyVaultId: keyVault.outputs.id
    keyVaultLocation: location
    searchServiceId: search.outputs.id
    searchEndpoint: search.outputs.endpoint
    storageAccountId: storage.outputs.id
    storageBlobEndpoint: storage.outputs.blobEndpoint
    cosmosAccountId: cosmos.outputs.id
    cosmosEndpoint: cosmos.outputs.endpoint
    knowledgeBaseConnectionName: 'kb-sharecloud-kb-9kdyn'
    knowledgeBaseName: 'sharecloud-kb'
    knowledgeBaseMcpEndpoint: '${search.outputs.endpoint}/knowledgebases/sharecloud-kb/mcp?api-version=2026-05-01-preview'
  }
}

output resourceGroupName string = resourceGroup().name
output location string = location
output virtualNetworkId string = networking.outputs.virtualNetworkId
output subnetId string = networking.outputs.subnetId
output logAnalyticsId string = monitoring.outputs.logAnalyticsId
output applicationInsightsId string = monitoring.outputs.applicationInsightsId
output storageAccountId string = storage.outputs.id
output cosmosAccountId string = cosmos.outputs.id
output keyVaultId string = keyVault.outputs.id
output searchServiceId string = search.outputs.id
output foundryAccountId string = foundry.outputs.foundryAccountId
output foundryProjectId string = foundry.outputs.foundryProjectId
output foundryProjectEndpoint string = foundry.outputs.projectEndpoint
output projectConnectionsManaged bool = manageProjectConnections
