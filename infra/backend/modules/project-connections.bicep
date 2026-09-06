@description('This module manages only non-secret project connections. It is disabled by default in the parent template for adoption safety.')
param foundryAccountName string
param foundryProjectName string
param keyVaultId string
param keyVaultLocation string
param searchServiceId string
param searchEndpoint string
param storageAccountId string
param storageBlobEndpoint string
param cosmosAccountId string
param cosmosEndpoint string
param knowledgeBaseConnectionName string
param knowledgeBaseName string
param knowledgeBaseMcpEndpoint string

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: foundryAccountName
}

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' existing = {
  parent: foundryAccount
  name: foundryProjectName
}

// The current resource provider returns AccountManagedIdentity and
// ProjectManagedIdentity even though the published 2025-06-01 type schema does
// not enumerate those discriminator values. any() preserves the live contract.
resource keyVaultConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: foundryProject
  name: '${foundryAccountName}-keyvault'
  properties: any({
    authType: 'AccountManagedIdentity'
    category: 'AzureKeyVault'
    group: 'Azure'
    isDefault: true
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: keyVaultId
      location: keyVaultLocation
    }
    target: keyVaultId
    useWorkspaceManagedIdentity: false
  })
}

resource searchConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: foundryProject
  name: '${foundryAccountName}-aisearch-existing'
  properties: any({
    authType: 'AAD'
    category: 'CognitiveSearch'
    group: 'AzureAI'
    isDefault: true
    isSharedToAll: true
    metadata: {
      ApiVersion: '2024-05-01-preview'
      DeploymentApiVersion: '2023-11-01'
      ResourceId: searchServiceId
      location: keyVaultLocation
    }
    target: searchEndpoint
    useWorkspaceManagedIdentity: false
  })
}

resource storageConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: foundryProject
  name: '${foundryAccountName}-storage-existing'
  properties: any({
    authType: 'AAD'
    category: 'AzureStorageAccount'
    group: 'Azure'
    isDefault: true
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: storageAccountId
    }
    target: storageBlobEndpoint
    useWorkspaceManagedIdentity: false
  })
}

resource cosmosConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: foundryProject
  name: '${foundryAccountName}-cosmosdb-existing'
  properties: any({
    authType: 'AAD'
    category: 'CosmosDb'
    group: 'Azure'
    isDefault: true
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: cosmosAccountId
      location: keyVaultLocation
    }
    target: cosmosEndpoint
    useWorkspaceManagedIdentity: false
  })
}

resource knowledgeBaseConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: foundryProject
  name: knowledgeBaseConnectionName
  properties: any({
    audience: 'https://search.azure.com'
    authType: 'ProjectManagedIdentity'
    category: 'RemoteTool'
    group: 'GenericProtocol'
    isDefault: true
    isSharedToAll: false
    metadata: {
      knowledgeBaseName: knowledgeBaseName
      type: 'knowledgeBase_MCP'
    }
    target: knowledgeBaseMcpEndpoint
    useWorkspaceManagedIdentity: false
  })
}

output managedConnectionNames array = [
  keyVaultConnection.name
  searchConnection.name
  storageConnection.name
  cosmosConnection.name
  knowledgeBaseConnection.name
]
