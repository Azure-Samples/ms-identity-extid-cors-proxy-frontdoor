param tags object = {}

@description('The name of the SKU to use when creating the Front Door profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

param originUrl string
param customDomain string

param frontDoorEndpointName string
param frontDoorName string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-09-01' = {
  name: frontDoorName
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
  tags: tags
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-09-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
  tags: tags
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: replace(originUrl, '.', '-')
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    // healthProbeSettings: {
    //   probePath: '/'
    //   probeRequestType: 'HEAD'
    //   probeProtocol: 'Http'
    //   probeIntervalInSeconds: 100
    // }
  }
}

resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: replace(originUrl, '.', '-')
  parent: frontDoorOriginGroup
  properties: {
    hostName: originUrl
    httpPort: 80
    httpsPort: 443
    originHostHeader: originUrl
    priority: 1
    weight: 1000
  }
}

module frontDoorCustomDomain './frontdoor-customdomain.bicep' = {
  name: 'customDomain'
  params: {
    frontDoorProfileName: frontDoorProfile.name
    customDomain: customDomain
  }
}
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-09-01' = {
  name: 'default-route'
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    customDomains: [
      {
        id: frontDoorCustomDomain.outputs.frontDoorCustomDomainId
      }
    ]
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

output customDomainValidationDnsTxtRecordName string = frontDoorCustomDomain.outputs.customDomainValidationDnsTxtRecordName
output customDomainValidationDnsTxtRecordValue string = frontDoorCustomDomain.outputs.customDomainValidationDnsTxtRecordValue
output customDomainValidationExpiry string = frontDoorCustomDomain.outputs.customDomainValidationExpiry
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
