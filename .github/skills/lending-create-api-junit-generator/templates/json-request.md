# LoanIQ Create API — JSON Request Structure

## Basic Create Request

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
          "name": "Create{EntityName}Integration",
          "className": "Create{EntityName}Integration",
          "group": [
            {
              "name": "heading",
              "item": [
                {
                  "attribute": "idempotencyKey",
                  "valueType": "String",
                  "value": "UNIQUE_KEY_12345"
                },
                {
                  "attribute": "identifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "ParentIdentifier",
                        "className": "ParentIdentifier",
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
                                "value": "PARENT_001"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "primitiveField1",
                  "valueType": "String",
                  "value": "value1"
                },
                {
                  "attribute": "primitiveField2",
                  "valueType": "LiqDate",
                  "value": "2024-03-10"
                },
                {
                  "attribute": "primitiveField3",
                  "valueType": "BigDecimal",
                  "value": "1000.00"
                },
                {
                  "attribute": "nestedObject",
                  "valueType": "List",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "NestedObjectType",
                        "className": "NestedObjectType",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "nestedField1",
                                "valueType": "String",
                                "value": "nestedValue1"
                              },
                              {
                                "attribute": "nestedField2",
                                "valueType": "BigDecimal",
                                "value": "500.00"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                },
                {
                  "attribute": "collectionItems",
                  "valueType": "List",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "CollectionItemType",
                        "className": "CollectionItemType",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "itemField1",
                                "valueType": "String",
                                "value": "item1Value"
                              },
                              {
                                "attribute": "itemField2",
                                "valueType": "String",
                                "value": "item1Value2"
                              }
                            ]
                          }
                        ]
                      },
                      {
                        "name": "CollectionItemType",
                        "className": "CollectionItemType",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "itemField1",
                                "valueType": "String",
                                "value": "item2Value"
                              },
                              {
                                "attribute": "itemField2",
                                "valueType": "String",
                                "value": "item2Value2"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
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

## Example 1: Create Deal Request

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
          "name": "CreateDealIntegration",
          "className": "CreateDealIntegration",
          "group": [
            {
              "name": "heading",
              "item": [
                {
                  "attribute": "idempotencyKey",
                  "valueType": "String",
                  "value": "DEAL_CREATE_20240310_001"
                },
                {
                  "attribute": "dealName",
                  "valueType": "String",
                  "value": "Test Deal ABC Corp"
                },
                {
                  "attribute": "dealAlias",
                  "valueType": "String",
                  "value": "ABC_DEAL_2024"
                },
                {
                  "attribute": "productType",
                  "valueType": "String",
                  "value": "REVOLVER"
                },
                {
                  "attribute": "currencyCode",
                  "valueType": "String",
                  "value": "USD"
                },
                {
                  "attribute": "proposedCloseDate",
                  "valueType": "LiqDate",
                  "value": "2024-04-15"
                },
                {
                  "attribute": "expirationDate",
                  "valueType": "LiqDate",
                  "value": "2027-04-15"
                },
                {
                  "attribute": "ansiId",
                  "valueType": "String",
                  "value": "00002"
                },
                {
                  "attribute": "department",
                  "valueType": "String",
                  "value": "CORP"
                },
                {
                  "attribute": "sourceRefNum",
                  "valueType": "String",
                  "value": "EXT_SYS_REF_12345"
                },
                {
                  "attribute": "systemSourceId",
                  "valueType": "String",
                  "value": "EXTERNAL_SYSTEM_001"
                },
                {
                  "attribute": "adminAgent",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "DealAdminAgent",
                        "className": "DealAdminAgent",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "lenderLegalName",
                                "valueType": "String",
                                "value": "ABC Bank"
                              },
                              {
                                "attribute": "servicing",
                                "valueType": "Boolean",
                                "value": "true"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "borrower",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "BorrowerIdentifier",
                        "className": "BorrowerIdentifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "identifierType",
                                "valueType": "String",
                                "value": "SID"
                              },
                              {
                                "attribute": "identifierValue",
                                "valueType": "String",
                                "value": "CUST_12345"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "additionalFields",
                  "valueType": "List",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "AdditionalFieldIntegration",
                        "className": "AdditionalFieldIntegration",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "fieldName",
                                "valueType": "String",
                                "value": "CustomField1"
                              },
                              {
                                "attribute": "fieldType",
                                "valueType": "String",
                                "value": "LIST"
                              },
                              {
                                "attribute": "fieldValue",
                                "valueType": "String",
                                "value": "Option1"
                              }
                            ]
                          }
                        ]
                      },
                      {
                        "name": "AdditionalFieldIntegration",
                        "className": "AdditionalFieldIntegration",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "fieldName",
                                "valueType": "String",
                                "value": "CustomField2"
                              },
                              {
                                "attribute": "fieldType",
                                "valueType": "String",
                                "value": "CODTB"
                              },
                              {
                                "attribute": "fieldValue",
                                "valueType": "String",
                                "value": "CODE_VALUE_001"
                              },
                              {
                                "attribute": "codeTableField",
                                "valueType": "String",
                                "value": "CUSTOM_CODE_TABLE"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
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

## Example 2: Create Facility Request

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
          "name": "CreateFacilityIntegration",
          "className": "CreateFacilityIntegration",
          "group": [
            {
              "name": "heading",
              "item": [
                {
                  "attribute": "idempotencyKey",
                  "valueType": "String",
                  "value": "FACILITY_CREATE_20240310_001"
                },
                {
                  "attribute": "dealIdentifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "DealIdentifier",
                        "className": "DealIdentifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "identifierType",
                                "valueType": "String",
                                "value": "name"
                              },
                              {
                                "attribute": "identifierValue",
                                "valueType": "String",
                                "value": "Test Deal ABC Corp"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "facilityName",
                  "valueType": "String",
                  "value": "Revolver Facility"
                },
                {
                  "attribute": "facilityType",
                  "valueType": "String",
                  "value": "REVOLVER"
                },
                {
                  "attribute": "currencyCode",
                  "valueType": "String",
                  "value": "USD"
                },
                {
                  "attribute": "globalAmount",
                  "valueType": "Money",
                  "value": "10000000.00"
                },
                {
                  "attribute": "effectiveDate",
                  "valueType": "LiqDate",
                  "value": "2024-03-10"
                },
                {
                  "attribute": "expirationDate",
                  "valueType": "LiqDate",
                  "value": "2027-03-10"
                },
                {
                  "attribute": "ansiId",
                  "valueType": "String",
                  "value": "00002"
                },
                {
                  "attribute": "primaryBorrowerIdentifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "BorrowerIdentifier",
                        "className": "BorrowerIdentifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "identifierType",
                                "valueType": "String",
                                "value": "SID"
                              },
                              {
                                "attribute": "identifierValue",
                                "valueType": "String",
                                "value": "CUST_12345"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "penaltySpread",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "PenaltySpreadIntegration",
                        "className": "PenaltySpreadIntegration",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "penaltySpreadRate",
                                "valueType": "BigDecimal",
                                "value": "0.50"
                              },
                              {
                                "attribute": "graceNumberOfDays",
                                "valueType": "Integer",
                                "value": "5"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "lateChargeRule",
                  "valueType": "String",
                  "value": "LATE_CHARGE_RULE_001"
                },
                {
                  "attribute": "additionalFields",
                  "valueType": "List",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "AdditionalFieldIntegration",
                        "className": "AdditionalFieldIntegration",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "fieldName",
                                "valueType": "String",
                                "value": "FacilityCustomField1"
                              },
                              {
                                "attribute": "fieldType",
                                "valueType": "String",
                                "value": "LIST"
                              },
                              {
                                "attribute": "fieldValue",
                                "valueType": "String",
                                "value": "Value1"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
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

## Example 3: Create Upfront Fee Request

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
          "name": "CreateUpfrontFeeIntegration",
          "className": "CreateUpfrontFeeIntegration",
          "group": [
            {
              "name": "heading",
              "item": [
                {
                  "attribute": "idempotencyKey",
                  "valueType": "String",
                  "value": "UPFRONT_FEE_CREATE_20240310_001"
                },
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
                                "attribute": "ownerIdentifierType",
                                "valueType": "String",
                                "value": "name"
                              },
                              {
                                "attribute": "ownerIdentifierValue",
                                "valueType": "String",
                                "value": "Test Deal ABC Corp"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "amount",
                  "valueType": "Money",
                  "value": "25000.00"
                },
                {
                  "attribute": "currencyCode",
                  "valueType": "String",
                  "value": "USD"
                },
                {
                  "attribute": "effectiveDate",
                  "valueType": "LiqDate",
                  "value": "2024-03-10"
                },
                {
                  "attribute": "branchCode",
                  "valueType": "String",
                  "value": "00002"
                },
                {
                  "attribute": "commentText",
                  "valueType": "String",
                  "value": "Initial upfront fee for deal setup"
                },
                {
                  "attribute": "borrowerIdentifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "BorrowerIdentifier",
                        "className": "BorrowerIdentifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "identifierType",
                                "valueType": "String",
                                "value": "SID"
                              },
                              {
                                "attribute": "identifierValue",
                                "valueType": "String",
                                "value": "CUST_12345"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "servicingGroup",
                  "valueType": "List",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "ServicingGroupIntegration",
                        "className": "ServicingGroupIntegration",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "groupMembers",
                                "valueType": "List",
                                "valueList": {
                                  "liqBusinessObject": [
                                    {
                                      "name": "ServicingGroupMember",
                                      "className": "ServicingGroupMember",
                                      "group": [
                                        {
                                          "item": [
                                            {
                                              "attribute": "memberName",
                                              "valueType": "String",
                                              "value": "John Doe"
                                            },
                                            {
                                              "attribute": "memberRole",
                                              "valueType": "String",
                                              "value": "PRIMARY"
                                            }
                                          ]
                                        }
                                      ]
                                    }
                                  ]
                                }
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                },
                {
                  "attribute": "feeDetails",
                  "valueType": "List",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "FeeDetails",
                        "className": "FeeDetails",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "feeType",
                                "valueType": "String",
                                "value": "UPFRONT"
                              },
                              {
                                "attribute": "feeAmount",
                                "valueType": "Money",
                                "value": "15000.00"
                              },
                              {
                                "attribute": "feePercentage",
                                "valueType": "BigDecimal",
                                "value": "0.15"
                              }
                            ]
                          }
                        ]
                      },
                      {
                        "name": "FeeDetails",
                        "className": "FeeDetails",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "feeType",
                                "valueType": "String",
                                "value": "COMMITMENT"
                              },
                              {
                                "attribute": "feeAmount",
                                "valueType": "Money",
                                "value": "10000.00"
                              },
                              {
                                "attribute": "feePercentage",
                                "valueType": "BigDecimal",
                                "value": "0.10"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
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

## Example 4: Create Loan Drawdown Request

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
          "name": "CreateLoanDrawdownIntegration",
          "className": "CreateLoanDrawdownIntegration",
          "group": [
            {
              "name": "heading",
              "item": [
                {
                  "attribute": "idempotencyKey",
                  "valueType": "String",
                  "value": "LOAN_DRAWDOWN_CREATE_20240310_001"
                },
                {
                  "attribute": "facilityIdentifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "FacilityIdentifier",
                        "className": "FacilityIdentifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "identifierType",
                                "valueType": "String",
                                "value": "controlNumber"
                              },
                              {
                                "attribute": "identifierValue",
                                "valueType": "String",
                                "value": "12345678"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "borrowerIdentifier",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "CustomerIdentifier",
                        "className": "CustomerIdentifier",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "identifierType",
                                "valueType": "String",
                                "value": "SID"
                              },
                              {
                                "attribute": "identifierValue",
                                "valueType": "String",
                                "value": "CUST_12345"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  "valueType": "List"
                },
                {
                  "attribute": "requestedAmount",
                  "valueType": "Money",
                  "value": "500000.00"
                },
                {
                  "attribute": "currencyCode",
                  "valueType": "String",
                  "value": "USD"
                },
                {
                  "attribute": "effectiveDate",
                  "valueType": "LiqDate",
                  "value": "2024-03-15"
                },
                {
                  "attribute": "maturityDate",
                  "valueType": "LiqDate",
                  "value": "2024-09-15"
                },
                {
                  "attribute": "pricingOption",
                  "valueType": "String",
                  "value": "LIBOR"
                },
                {
                  "attribute": "rateType",
                  "valueType": "String",
                  "value": "FLOAT"
                },
                {
                  "attribute": "interestRateIsFloating",
                  "valueType": "Boolean",
                  "value": "true"
                },
                {
                  "attribute": "repricingFrequencyApplies",
                  "valueType": "Boolean",
                  "value": "true"
                },
                {
                  "attribute": "sourceRefNum",
                  "valueType": "String",
                  "value": "EXT_LOAN_REF_12345"
                },
                {
                  "attribute": "systemSourceId",
                  "valueType": "String",
                  "value": "EXTERNAL_LOAN_SYSTEM_001"
                },
                {
                  "attribute": "ostSpreadAdjustmentComponents",
                  "valueType": "List",
                  "valueList": {
                    "liqBusinessObject": [
                      {
                        "name": "SpreadAdjustmentComponentOverrideIntegration",
                        "className": "SpreadAdjustmentComponentOverrideIntegration",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "componentName",
                                "valueType": "String",
                                "value": "Base Spread"
                              },
                              {
                                "attribute": "componentRate",
                                "valueType": "BigDecimal",
                                "value": "0.75"
                              }
                            ]
                          }
                        ]
                      },
                      {
                        "name": "SpreadAdjustmentComponentOverrideIntegration",
                        "className": "SpreadAdjustmentComponentOverrideIntegration",
                        "group": [
                          {
                            "item": [
                              {
                                "attribute": "componentName",
                                "valueType": "String",
                                "value": "Credit Adjustment"
                              },
                              {
                                "attribute": "componentRate",
                                "valueType": "BigDecimal",
                                "value": "0.25"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
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

## Common Request Patterns

### Idempotency Key Pattern

Always include an idempotency key for create operations:

```json
{
  "attribute": "idempotencyKey",
  "valueType": "String",
  "value": "UNIQUE_KEY_PREFIX_TIMESTAMP"
}
```

### Identifier Pattern

Use consistent identifier structures across all APIs:

```json
{
  "attribute": "{entity}Identifier",
  "valueList": {
    "liqBusinessObject": [
      {
        "name": "{Entity}Identifier",
        "className": "{Entity}Identifier",
        "group": [
          {
            "item": [
              {
                "attribute": "identifierType",
                "valueType": "String",
                "value": "id|name|alias|sid"
              },
              {
                "attribute": "identifierValue",
                "valueType": "String",
                "value": "{value}"
              }
            ]
          }
        ]
      }
    ]
  },
  "valueType": "List"
}
```

### Money/Amount Pattern

```json
{
  "attribute": "amount",
  "valueType": "Money",
  "value": "1000000.00"
}
```

### Date Pattern

```json
{
  "attribute": "effectiveDate",
  "valueType": "LiqDate",
  "value": "2024-03-10"
}
```

### Additional Fields Pattern

```json
{
  "attribute": "additionalFields",
  "valueType": "List",
  "valueList": {
    "liqBusinessObject": [
      {
        "name": "AdditionalFieldIntegration",
        "className": "AdditionalFieldIntegration",
        "group": [
          {
            "item": [
              {
                "attribute": "fieldName",
                "valueType": "String",
                "value": "CustomFieldName"
              },
              {
                "attribute": "fieldType",
                "valueType": "String",
                "value": "LIST|CODTB|DATE|TIME|PRCNT|BSPNT|MISCD"
              },
              {
                "attribute": "fieldValue",
                "valueType": "String",
                "value": "FieldValue"
              },
              {
                "attribute": "codeTableField",
                "valueType": "String",
                "value": "CODE_TABLE_NAME"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### Source System Fields Pattern

```json
{
  "attribute": "sourceRefNum",
  "valueType": "String",
  "value": "EXTERNAL_REFERENCE_NUMBER"
},
{
  "attribute": "systemSourceId",
  "valueType": "String",
  "value": "EXTERNAL_SYSTEM_ID"
}
```
