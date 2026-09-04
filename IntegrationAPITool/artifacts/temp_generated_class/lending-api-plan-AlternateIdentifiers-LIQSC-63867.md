# Lending API Implementation Plan: AlternateIdentifiers

## Request

- **Entity:** `AlternateIdentifiers`
- **JIRA story:** `LIQSC-63867`
- **Requirement workbook:** `IntegrationAPITool/artifacts/requirement_doc/AlternateIdentifiers.xlsx`
- **Operation represented by the workbook:** Query (GetById)
- **Target integration class:** `LiqAPIAlternateIdentifiersQueryIntegration`
- **Target response class:** `LiqAPIAlternateIdentifiersIntegrationAsReturnValue`
- **Target package:** `com.finastra.liq.api.rest.executable.fee`

## Requirements summary

### Query input

The query accepts one `objectIdentifier` containing these required fields:

| Field | Type | Required | Rules |
|---|---|---:|---|
| `objectType` | String | Yes | Support `OST` (Outstanding) and `LNID` (Outstanding Transaction). |
| `identfierType` | String | Yes | Support `id` and `alias`; only one identifier with its object type is supplied. |
| `identifierValue` | String | Yes | Value of the identifier selected by `identfierType`. |

### Query output

The response contains required status and schedule fields plus a list of returned identifiers:

| Field | Type | Required | Rules |
|---|---|---:|---|
| `success` | String | Yes | `'true'` or `'false'`. |
| `Message` | String | Yes | Return API messages; distinguish errors and warnings where applicable. |
| `hasSchedule` | Boolean | Yes | When `true`, return `scheduleType`; when `false`, omit it. |
| `scheduleType` | String | Yes | Current schedule type, for example `FLEX`, `PRIN`, or `PRINB`. |
| `objectIdentifier` | List | Yes | Return identifiers associated with the requested object. |
| `objectIdentifier.objectType` | String | Yes | Return the same object type supplied in the request (`OST` or `LNID`). |
| `objectIdentifier.identfierType` | String | Yes | Identifier type (`id` or `alias`). |
| `objectIdentifier.identifierValue` | String | Yes | Identifier value. Include the identifier used in the request and all unique identifiers for the object. |

## Implementation steps

1. Inspect the existing LoanIQ query integration hierarchy and reuse the standard query, identifier, validation, and response abstractions.
2. Add or update the `AlternateIdentifiers` query model so the request serializes the `objectIdentifier` fields with the exact API names from the workbook, including the existing `identfierType` spelling.
3. Implement the query integration using the configured SOAP/API operation and map the returned success, message, schedule, and identifier-list fields.
4. Validate required input, supported object types (`OST`, `LNID`), supported identifier types (`id`, `alias`), and the single-object-identifier constraint before execution.
5. Apply conditional response validation: `scheduleType` must be present when `hasSchedule` is true and absent when it is false.
6. Preserve all unique identifiers returned by the API and verify that the requested identifier is present in the response.
7. Add focused integration coverage for valid ID and alias requests for both object types, missing/invalid identifier values and types, response identifier preservation, API errors/warnings, and both schedule branches.
8. Update generated/request-response examples or registration metadata only where required by the existing integration conventions.

## Acceptance criteria

- A valid ID or alias query resolves either an outstanding or outstanding transaction.
- Invalid, missing, or conflicting identifier input fails validation with the repository's standard error handling.
- The response exposes `success`, `Message`, `hasSchedule`, and the complete `objectIdentifier` list.
- `objectType` is preserved in every returned identifier.
- `scheduleType` follows the `hasSchedule` conditional rule.
- Error and warning messages remain distinguishable and are not discarded.
- Existing query integrations and generated artifacts remain unchanged.

## Scope and validation

This plan is limited to the `AlternateIdentifiers` query API described in the workbook. Review the implementation diff for generated-file scope, run the existing targeted query/integration tests, and do not modify unrelated repository source or configuration.
