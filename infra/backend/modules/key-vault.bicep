param location string
param tags object = {}
param tenantId string
param keyVaultName string
param subnetId string
param foundryPrincipalId string
param preserveLegacyAccessPolicy bool = true

var accessPolicies = preserveLegacyAccessPolicy ? [
  {
    tenantId: tenantId
    objectId: foundryPrincipalId
    permissions: {
      certificates: []
      keys: []
      secrets: [
        'get'
        'list'
        'set'
        'delete'
      ]
      storage: []
    }
  }
] : []

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: accessPolicies
    enableRbacAuthorization: true
    enableSoftDelete: true
    publicNetworkAccess: 'Enabled'
    softDeleteRetentionInDays: 90
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: [
        {
          id: subnetId
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
}

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
