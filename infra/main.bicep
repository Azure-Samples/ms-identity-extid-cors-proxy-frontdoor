targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }

@description('The origin domain to allow CORS requests from in the format of SCHEME://DOMAIN:PORT, e.g. http://localhost:3000')
param corsAllowedOrigin string

@description('The subdomain of the External ID tenant that we will proxy (This is the portion of the primary domain before the .onmicrosoft.com part, e.g. mytenant)')
param tenantSubdomain string

param customDomain string

param resourceGroupName string = ''
param logAnalyticsWorkspaceName string = ''
param frontDoorName string = ''
param frontDoorEndpointName string = ''

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// A unique token to be used in naming resources.
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module frontDoor './modules/frontdoor.bicep' = {
  name: 'frontdoor'
  scope: rg
  params: {
    tags: tags
    frontDoorEndpointName: !empty(frontDoorEndpointName) ? frontDoorEndpointName : '${abbrs.networkFrontDoorEndpoints}${resourceToken}'
    frontDoorName: !empty(frontDoorName) ? frontDoorName : '${abbrs.networkFrontDoors}${resourceToken}'
    originUrl: '${tenantSubdomain}.ciamlogin.com'
    customDomain: customDomain
    corsAllowedOrigin: corsAllowedOrigin
    logAnalyticsName: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
  }
}

module logAnalytics 'core/monitor/loganalytics.bicep' = {
  name: 'logAnalytics'
  scope: rg
  params: {
    name: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId

output CUSTOM_DOMAIN_DNS_TXT_NAME string = frontDoor.outputs.customDomainValidationDnsTxtRecordName
output CUSTOM_DOMAIN_DNS_TXT_VALUE string = frontDoor.outputs.customDomainValidationDnsTxtRecordValue
output CUSTOM_DOMAIN_DNS_EXPIRY string = frontDoor.outputs.customDomainValidationExpiry

output FRONTDOOR_ENDPOINT_NAME string = frontDoor.outputs.frontDoorEndpointHostName
