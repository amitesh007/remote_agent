# Generic JSON Delete Request Payload Template

This file defines the universal JSON structure used by `getMainObjectFromJsonDelete()` for Delete API test methods.

---

## Basic Delete Request Structure (Identifier-Based)

Used by: Deal, UpfrontFee, LoanDrawdown, LoanPrincipalPayment

```json
{
  "header": {
    "appId": "LIQAPI",
    "isB2B": false
  },
  "businessObjectName": "Delete{BusinessObject}Integration",
  "className": "com.misys.liq.api.rest.executable.{domain}.LiqAPIDelete{BusinessObject}Integration",
  "groups": [
    {
      "groupName": "{BusinessObject}Identifier",
      "attributes": [
        {
          "attribute": "identifierType",
          "valueType": "String",
          "value": "id"
        },
        {
          "attribute": "identifierValue",
          "valueType": "String",
          "value": "{dynamicValue_from_CREATE_response}"
        }
      ]
    }
  ]
}
```

---

## Delete Request with Outstanding Transaction Identifier

Used by: LoanDrawdown, LoanPrincipalPayment

```json
{
  "header": {
    "appId": "LIQAPI",
    "isB2B": false
  },
  "businessObjectName": "Delete{BusinessObject}Integration",
  "className": "com.misys.liq.api.rest.executable.outstanding.{subdomain}.LiqAPIDelete{BusinessObject}Integration",
  "groups": [
    {
      "groupName": "outstandingTransactionIdentifier",
      "attributes": [
        {
          "attribute": "identifierType",
          "valueType": "String",
          "value": "transactionId"
        },
        {
          "attribute": "identifierValue",
          "valueType": "String",
          "value": "{dynamicValue_from_CREATE_response}"
        }
      ]
    }
  ]
}
```

---

## Delete Request with Owner Identifier Pattern

Used by: ProductGuarantee, MISCode

```json
{
  "header": {
    "appId": "LIQAPI",
    "isB2B": false
  },
  "businessObjectName": "Delete{BusinessObject}Integration",
  "className": "com.misys.liq.api.rest.executable.{domain}.LiqAPIDelete{BusinessObject}Integration",
  "groups": [
    {
      "groupName": "ownerIdentifier",
      "attributes": [
        {
          "attribute": "ownerType",
          "valueType": "String",
          "value": "DEA"
        },
        {
          "attribute": "ownerIdentifierType",
          "valueType": "String",
          "value": "id"
        },
        {
          "attribute": "ownerIdentifierValue",
          "valueType": "String",
          "value": "{dynamicValue_from_CREATE_response}"
        }
      ]
    },
    {
      "groupName": "{businessObject}Identifiers",
      "attributes": [
        {
          "attribute": "identifierType",
          "valueType": "String",
          "value": "id"
        },
        {
          "attribute": "identifierValue",
          "valueType": "String",
          "value": "{dynamicValue_from_CREATE_response}"
        }
      ]
    }
  ]
}
```

---

## Delete Request with If-Match Timestamp

Used by: Deal, UpfrontFee, ProductGuarantee

```json
{
  "header": {
    "appId": "LIQAPI",
    "isB2B": false,
    "matchUpdatedTimestamp": "{timestamp_from_QUERY_response}"
  },
  "businessObjectName": "Delete{BusinessObject}Integration",
  "className": "com.misys.liq.api.rest.executable.{domain}.LiqAPIDelete{BusinessObject}Integration",
  "groups": [
    {
      "groupName": "{BusinessObject}Identifier",
      "attributes": [
        {
          "attribute": "identifierType",
          "valueType": "String",
          "value": "id"
        },
        {
          "attribute": "identifierValue",
          "valueType": "String",
          "value": "{dynamicValue_from_CREATE_response}"
        }
      ]
    }
  ]
}
```

---

## Delete Request with Non-Primitive Collection (MIS Codes Example)

Used by: MISCode

```json
{
  "header": {
    "appId": "LIQAPI",
    "isB2B": false
  },
  "businessObjectName": "DeleteMISCodeIntegration",
  "className": "com.misys.liq.api.rest.executable.miscode.LiqAPIDeleteMISCodeIntegration",
  "groups": [
    {
      "groupName": "ownerIdentifier",
      "attributes": [
        {
          "attribute": "ownerType",
          "valueType": "String",
          "value": "DEA"
        },
        {
          "attribute": "ownerIdentifierType",
          "valueType": "String",
          "value": "dealName"
        },
        {
          "attribute": "ownerIdentifierValue",
          "valueType": "String",
          "value": "TestDeal001"
        }
      ]
    },
    {
      "groupName": "misCodes",
      "valueType": "List",
      "valueList": [
        {
          "groupName": "misCode",
          "attributes": [
            {
              "attribute": "type",
              "valueType": "String",
              "value": "MIS_TYPE_1"
            },
            {
              "attribute": "value",
              "valueType": "String",
              "value": "MIS_VALUE_1"
            },
            {
              "attribute": "valueType",
              "valueType": "String",
              "value": "MIS_VALUETYPE_1"
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Where to Find Sample JSON Payloads

1. **Temp generation folder** (for newly created business objects):
   ```
   FLIQ-liqjava/IntegrationAPITool/artifacts/temp_generated_class/
   ```
   Check for `Delete{BusinessObject}Integration.json` or similar.

2. **Test resources folder** (for established objects):
   ```
   LoanIQ/test-resources/json/{domain}/Delete{BusinessObject}Integration.json
   ```

3. **GeneralIntegrationMapping enum** — look for the `getJsonFileName()` method of the DELETE_ constant to find the exact path.

---

## Template Usage in Test Methods

```java
// Load delete DTO from JSON template:
liqAPiDataDelete = getMainObjectFromJsonDelete(
    GeneralIntegrationMapping.DELETE_{BUSINESS_OBJECT_UPPER}_{CONTEXT}.toString(),
    LiqAPIDelete{BusinessObject}Integration.class);

// Then override identifier values with dynamic data from CREATE response:
liqAPiDataDelete.get{Identifier}().setIdentifierValue(createdId);
liqAPiDataDelete.setMatchUpdatedTimestamp(timestampFromQuery);
```
