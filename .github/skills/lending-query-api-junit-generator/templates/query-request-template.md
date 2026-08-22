# Generic Query Request Payload Template

> This template provides the generic JSON structure for a Query (GET) request payload for any LoanIQ business object. Replace `{Entity}`, `{EntityName}`, and identifier values with actual values for the specific business object.

## Standard Entity Query Template

```json
{
  "header": {
    "appId": "INTR",
    "isB2B": true,
    "isAdmin": false
  },
  "attributes": {
    "liqBusinessObjects": {
      "liqBusinessObject": [
        {
          "name": "Query{EntityName}Integration",
          "className": "Query{EntityName}Integration",
          "group": [
            {
              "name": "heading",
              "item": [
                {
                  "attribute": "{entity}Identifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "{EntityName}Identifier",
                        "className": "{EntityName}Identifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "identifierType",
                                "valueType": "String",
                                "value": "id"
                              },
                              {
                                "attribute": "identifierValue",
                                "valueType": "String",
                                "value": "{ENTITY_ID}"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                }
              ]
            }
          ]
        }
      ]
    }
  }
}
```

## Transaction Query Template (LoanDrawdown, LoanInterestPayment, etc.)

```json
{
  "header": {
    "appId": "INTR",
    "isB2B": true,
    "isAdmin": false
  },
  "attributes": {
    "liqBusinessObjects": {
      "liqBusinessObject": [
        {
          "name": "Query{EntityName}Integration",
          "className": "Query{EntityName}Integration",
          "group": [
            {
              "name": "heading",
              "item": [
                {
                  "attribute": "outstandingTransactionIdentifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "OutstandingTransactionIdentifier",
                        "className": "OutstandingTransactionIdentifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "identifierType",
                                "valueType": "String",
                                "value": "transactionId"
                              },
                              {
                                "attribute": "identifierValue",
                                "valueType": "String",
                                "value": "{TRANSACTION_ID}"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                }
              ]
            }
          ]
        }
      ]
    }
  }
}
```

## Polymorphic Owner Query Template (MISCode, AdditionalFields)

```json
{
  "header": {
    "appId": "INTR",
    "isB2B": true,
    "isAdmin": false
  },
  "attributes": {
    "liqBusinessObjects": {
      "liqBusinessObject": [
        {
          "name": "Query{EntityName}Integration",
          "className": "Query{EntityName}Integration",
          "group": [
            {
              "name": "heading",
              "item": [
                {
                  "attribute": "ownerIdentifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "OwnerIdentifier",
                        "className": "OwnerIdentifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "ownerType",
                                "valueType": "String",
                                "value": "DEA"
                              },
                              {
                                "attribute": "ownerIdentiferType",
                                "valueType": "String",
                                "value": "id"
                              },
                              {
                                "attribute": "ownerIdentiferValue",
                                "valueType": "String",
                                "value": "{OWNER_ID}"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                }
              ]
            }
          ]
        }
      ]
    }
  }
}
```

---

## Usage in Tests

The JSON template files are placed under:
- `FLIQ-liqjava\IntegrationAPITool\artifacts\temp_generated_class\` — generated by the tool
- `LoanIQ\test\resources\{domain}\Query{Entity}Integration.json` — final location

Each test method loads the template via `GeneralIntegrationMapping` enum which maps to the JSON file path:

```java
// Standard entity
liqAPiDataQuery = getMainObjectFromJsonQuery(
    GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
    LiqAPIQuery{Entity}Integration.class);

// Transaction entity
LiqAPIQuery{Entity}Integration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
    GeneralIntegrationMapping.QUERY_{ENTITY}_VALID.toString(),
    LiqAPIQuery{Entity}Integration.class);
```
