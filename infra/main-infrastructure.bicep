param location string
param tags object
param resourceToken string
// !PATCH Naming Conventions
var resourcePrefix = 'sharecloud-frontend'
var acrSuffix = substring(resourceToken, 0, 6)

// !PATCH Define existing Log Workspace
@description('Resource ID of the existing shared Log Analytics workspace')
param logAnalyticsWorkspaceId string

var abbrs = loadJsonContent('./abbreviations.json')

var defaultTags = {
  'azd-env-name': resourceToken
}

var allTags = union(tags, defaultTags)

// Application Insights (backend)
module appInsights './core/host/application-insights.bicep' = {
  name: 'appInsights'
  params: {
    name: '${resourcePrefix}-insights'
    location: location
    tags: allTags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

// Application Insights (frontend) — separate resource so browser telemetry doesn't pollute server metrics
module appInsightsFrontend './core/host/application-insights.bicep' = {
  name: 'appInsightsFrontend'
  params: {
    name: '${resourcePrefix}-insights-fe'
    location: location
    tags: allTags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

// Container Registry
module containerRegistry './core/host/container-registry.bicep' = {
  name: 'container-registry'
  params: {
    name: 'sharecloudfrontendacr${acrSuffix}'
    location: location
    tags: allTags
    acrPullPrincipalId: managedIdentity.properties.principalId
  }
}

// Container Apps Environment
module containerAppsEnvironment './core/host/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  params: {
    name: '${resourcePrefix}-env'
    location: location
    tags: allTags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output appInsightsConnectionString string = appInsights.outputs.connectionString
output appInsightsFrontendConnectionString string = appInsightsFrontend.outputs.connectionString
output containerRegistryName string = containerRegistry.outputs.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.id

// User-assigned managed identity — created independently so its principalId
// is available for both Entra FIC and Container App/ACR assignment without circular dependency.
// isolationScope: Regional ensures the identity can only be used in the deployment region.
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: '${resourcePrefix}-identity'
  location: location
  tags: allTags
  properties: {
    isolationScope: 'Regional'
  }
}

output managedIdentityId string = managedIdentity.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
