param location string
param tags object = {}
param virtualNetworkName string
param subnetName string
param vnetAddressPrefixes array
param subnetAddressPrefixes array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-03-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    enableDdosProtection: false
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefixes: subnetAddressPrefixes
          defaultOutboundAccess: false
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.CognitiveServices'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.AzureCosmosDB'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                'francecentral'
                'francesouth'
              ]
            }
          ]
        }
      }
    ]
  }
}

output virtualNetworkId string = virtualNetwork.id
output subnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, subnetName)
