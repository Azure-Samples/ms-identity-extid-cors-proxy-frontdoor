
@description('The name of the FrontDoor profile resource')
@minLength(1)
param frontDoorProfileName string

@description('The External ID custom Domain URL for the endpoint')
@minLength(1)
param customDomain string


resource frontDoorCustomDomain 'Microsoft.Cdn/profiles/customDomains@2024-09-01' = {
  name: replace(customDomain, '.', '-')
  parent: frontDoorProfile
  properties: {
    hostName: customDomain
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-09-01' existing = {
  name: frontDoorProfileName
}

output frontDoorCustomDomainId string = frontDoorCustomDomain.id
output customDomainValidationDnsTxtRecordName string = '_dnsauth.${frontDoorCustomDomain.properties.hostName}'
output customDomainValidationDnsTxtRecordValue string = frontDoorCustomDomain.properties.validationProperties.validationToken
output customDomainValidationExpiry string = frontDoorCustomDomain.properties.validationProperties.expirationDate
