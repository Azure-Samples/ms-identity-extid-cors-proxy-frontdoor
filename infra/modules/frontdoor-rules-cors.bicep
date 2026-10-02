@description('The FrontDoor Profile to add the rules to')
param frontDoorProfileName string

@description('The origin domain to allow CORS requests from in the format of SCHEME://DOMAIN:PORT, e.g. http://localhost:3000')
param corsAllowedOrigin string = ''

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-09-01' existing = {
  name: frontDoorProfileName
}

resource frontDoorRuleSet 'Microsoft.Cdn/profiles/ruleSets@2024-09-01' = {
  name: 'CORSRuleSet'
  parent: frontDoorProfile
}

resource corsProxyRule 'Microsoft.Cdn/profiles/ruleSets/rules@2024-09-01' = {
  name: 'CORSRule'
  parent: frontDoorRuleSet
  properties: {
    order: 1
    conditions: [
      {
        name: 'RequestHeader'
        parameters: {
          operator: 'Equal'
          selector: 'Origin'
          matchValues: [corsAllowedOrigin]
          typeName: 'DeliveryRuleRequestHeaderConditionParameters'
        }
      }
    ]
    actions: [
      {
        name: 'ModifyResponseHeader'
        parameters: {
          headerAction: 'Overwrite'
          headerName: 'Access-Control-Allow-Origin'
          typeName: 'DeliveryRuleHeaderActionParameters'
          value: corsAllowedOrigin
        }
      }
      {
        name: 'ModifyResponseHeader'
        parameters: {
          headerAction: 'Overwrite'
          headerName: 'Access-Control-Allow-Methods'
          typeName: 'DeliveryRuleHeaderActionParameters'
          value: '{http_req_header_Access-Control-Request-Method}'
        }
      }
      {
        name: 'ModifyResponseHeader'
        parameters: {
          headerAction: 'Overwrite'
          headerName: 'Access-Control-Allow-Headers'
          typeName: 'DeliveryRuleHeaderActionParameters'
          value: '{http_req_header_Access-Control-Request-Headers}'
        }
      }
    ]
  }

}
output frontDoorRuleSetId string = frontDoorRuleSet.id
