targetScope = 'resourceGroup'

@description('Read-only existence audit. This template declares no managed resources and therefore changes nothing.')
param names object = {
  virtualNetwork: 'sharecloud-vnet'
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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-03-01' existing = {
  name: names.virtualNetwork
}
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: names.logAnalytics
}
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: names.applicationInsights
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-06-01' existing = {
  name: names.storageAccount
}
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2025-04-15' existing = {
  name: names.cosmosAccount
}
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: names.keyVault
}
resource searchService 'Microsoft.Search/searchServices@2025-05-01' existing = {
  name: names.searchService
}
resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: names.foundryAccount
}
resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' existing = {
  parent: foundryAccount
  name: names.foundryProject
}
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' existing = {
  parent: foundryAccount
  name: names.modelDeployment
}

output resourceIds object = {
  virtualNetwork: virtualNetwork.id
  logAnalytics: logAnalytics.id
  applicationInsights: applicationInsights.id
  storageAccount: storageAccount.id
  cosmosAccount: cosmosAccount.id
  keyVault: keyVault.id
  searchService: searchService.id
  foundryAccount: foundryAccount.id
  foundryProject: foundryProject.id
  modelDeployment: modelDeployment.id
}
