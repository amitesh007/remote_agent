# Lending API Implementation Plan: AlternateIdentifiers

## Request

- **Entity:** `AlternateIdentifiers`
- **JIRA story:** `LIQSC-63867`
- **Requirement workbook:** `IntegrationAPITool/artifacts/requirement_doc/AlternateIdentifiers.xlsx`
- **Operation:** Query (`GetById`)
- **Package:** `com.finastra.liq.api.rest.executable.fee`

## Planned API surface

Implement the AlternateIdentifiers query integration using the existing LoanIQ REST API conventions:

- Add the query integration class `LiqAPIAlternateIdentifiersQueryIntegration`.
- Expose the query request fields `objectType`, `identfierType`, and `identifierValue` under the `objectIdentifier` category.
- All three request fields are required strings. The request is not a list and does not use translation, code-table, or SOAP mappings.
- Return `LiqAPIAlternateIdentifiersIntegrationAsReturnValue` with the fields described below.

## Request model and validation

| Field | Type | Required | Validation |
| --- | --- | --- | --- |
| `objectType` | `String` | Yes | Support `Outstanding` (`OST`) and `Outstanding Transaction` (`LNID`); use the bracketed code as the enum value. |
| `identfierType` | `String` | Yes | Support `id` and `alias` for both `Outstanding` and `Outstanding Transaction`. Only one identifier with its matching object type may be supplied. |
| `identifierValue` | `String` | Yes | Value of the identifier selected by `identfierType`. |

The implementation should reject incomplete or inconsistent identifier combinations before invoking the underlying LoanIQ operation.

## Response model

Return the query response with these required fields:

- `success` (`String`) containing `true` or `false`.
- `Message` (`String`) containing output messages. Error and warning messages should be distinguishable in the response representation.
- `hasSchedule` (`Boolean`) indicating whether a repayment schedule exists. When `true`, return `scheduleType`; when `false`, omit `scheduleType`.
- `scheduleType` (`String`) containing the current schedule type, such as `FLEX`, `PRIN`, or `PRINB`, when applicable.
- A list of `objectIdentifier` entries containing `objectType`, `identfierType`, and `identifierValue`. Preserve the input `objectType` and include all unique identifiers associated with the resolved object, including the identifier supplied in the request.

## Integration and mapping

1. Follow the existing query integration and endpoint naming patterns in the LoanIQ REST API source.
2. Map the request identifier category to the SOAP/API operation that resolves an outstanding or outstanding transaction.
3. Map the operation result into the response wrapper and nested identifier list.
4. Preserve the specified field names, including the workbook spelling `identfierType`, in the external API contract.
5. Apply the schedule conditional rule and separate error/warning messages during response mapping.
6. Keep the generated class and tests in the package and source layout used by neighboring lending APIs.

## Tests

Add focused integration/API tests covering:

1. Lookup by outstanding `id`.
2. Lookup by outstanding `alias`.
3. Lookup by outstanding transaction `id` and `alias`.
4. Rejection when `objectType`, `identfierType`, or `identifierValue` is missing.
5. Rejection of an unsupported object or identifier type and mismatched combinations.
6. A response containing multiple unique identifiers, including the requested identifier.
7. `hasSchedule=true` returning `scheduleType`.
8. `hasSchedule=false` omitting `scheduleType`.
9. Successful and failed responses, including separately represented warnings and errors.

## Acceptance criteria

- The query endpoint follows the repository's standard request, response, error, and authentication behavior.
- All workbook-required fields and validations are represented without changing their public names or types.
- Identifier and schedule conditional rules are enforced.
- Focused tests pass and cover both valid and invalid request/response paths.
