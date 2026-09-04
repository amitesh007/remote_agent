# Lending API Implementation Plan: AlternateIdentifiers

## Request

- **Entity:** `AlternateIdentifiers`
- **JIRA story:** `LIQSC-63867`
- **Requirement source:** `IntegrationAPITool/artifacts/requirement_doc/AlternateIdentifiers.xlsx`
- **Operation specified:** Query (`GetById` sheet)

## Scope

Implement the Alternate Identifiers query REST API and its integration models, following the existing LoanIQ REST API patterns. The spreadsheet identifies the integration class as `LiqAPIAlternateIdentifiersQueryIntegration` and the response class as `LiqAPIAlternateIdentifiersIntegrationAsReturnValue`, in package `com.finastra.liq.api.rest.executable.fee`.

No Create, Update, or Delete requirements are present in the workbook.

## Requirements extracted from the spreadsheet

### Query input

The query accepts one required `objectIdentifier` object containing:

| Field | Type | Required | Rules |
|---|---|---:|---|
| `objectType` | `String` | Yes | Support `OST` (Outstanding) and `LNID` (Outstanding Transaction). Use the code value as the enum value. |
| `identfierType` | `String` | Yes | Support `id` and `alias` for both supported object types. Only one identifier with its object type may be supplied. |
| `identifierValue` | `String` | Yes | Value of the identifier described by `identfierType`. |

### Query output

The response contains a required `success` string (`true`/`false`), required `Message` string/list output, and a required list of `objectIdentifier` values. Each returned object identifier contains:

| Field | Type | Required | Rules |
|---|---|---:|---|
| `objectType` | `String` | Yes | Return the same object type supplied in the request; support `OST` and `LNID`. |
| `identfierType` | `String` | Yes | Return supported `id`/`alias` identifier types and all unique identifiers associated with the requested object. |
| `identifierValue` | `String` | Yes | Returned identifier value. The input identifier must be included in the response. |

The sheet also lists `hasSchedule` and `scheduleType` output fields. These descriptions refer to repayment schedules for a Loan Initial Drawdown and do not align with Alternate Identifiers; confirm with the product owner whether they are accidental carry-over requirements before implementation. If confirmed as in scope, return `scheduleType` only when `hasSchedule` is `true`.

## Planned implementation

1. Inspect the existing query integration base classes, SOAP/function mappings, REST request/response model conventions, enum/code-table handling, and error-message conventions.
2. Add or update the Alternate Identifiers query integration class using the standard query execution path.
3. Add the request model for `objectIdentifier`, preserving the requirement spelling `identfierType` in the external contract unless the API specification confirms the corrected spelling; if a compatibility alias is needed, document and test both names.
4. Add the response model with `success`, `Message`, and the list of returned object identifiers. Ensure nested list serialization and deserialization match the existing API conventions.
5. Map `objectType` values `OST` and `LNID`, and identifier types `id` and `alias`, to the corresponding LoanIQ function inputs and outputs.
6. Validate that the request has exactly one supported object type, identifier type, and identifier value. Return the standard validation response for missing, unsupported, or conflicting values.
7. Ensure the response includes every unique identifier associated with the requested outstanding or outstanding transaction and includes the identifier used for the query.
8. Add focused unit/integration coverage for successful `OST` and `LNID` queries, `id` and `alias` inputs, returned identifier preservation, invalid combinations, missing required fields, response mapping, and the `hasSchedule`/`scheduleType` clarification if that requirement is retained.
9. Update API documentation or generated metadata only where required by the confirmed contract.

## Files expected to change

The implementation agent should locate the matching existing package and modify only the corresponding Alternate Identifiers query integration, request/response model, mapping/metadata, and test files. No unrelated source files should be changed.

## Open questions and risks

- The workbook uses `GetById` rather than the more common `GetByID`; treat it as the query sheet.
- `identfierType` is misspelled consistently in the workbook. Confirm whether that spelling is already part of the public contract before correcting it.
- The `hasSchedule` and `scheduleType` rows appear copied from a repayment-schedule requirement and conflict with this entity. Obtain clarification before exposing them.
- Confirm the exact LoanIQ function/service and existing model package location; the workbook's `SOAP_CLASS` cell is blank.

## Verification

- Run the repository's existing focused unit/integration tests for the query integration and model classes.
- Verify serialized request and response JSON against the approved Alternate Identifiers contract.
- Verify both supported object types, both identifier types, uniqueness, and standard error handling.
