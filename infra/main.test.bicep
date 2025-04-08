// This file is for doing static analysis and contains sensible defaults
// for PSRule to minimise false-positives and provide the best results.

// This file is not intended to be used as a runtime configuration file.

targetScope = 'subscription'

param location string = 'swedencentral'

module main 'main.bicep' = {
  name: 'main'
  params: {
    location: location
    environmentName: 'extid-cors-proxy'
    tenantSubdomain: 'myextid'
    corsAllowedOrigin: 'https://myextid.example.com'
    customDomain: 'auth.example.com'
  }
}
