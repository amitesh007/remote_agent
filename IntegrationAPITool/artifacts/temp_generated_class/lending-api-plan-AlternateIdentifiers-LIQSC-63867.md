# Lending API Implementation Plan: AlternateIdentifiers

## Plan Inputs

| Input | Value |
|---|---|
| Entity name | `AlternateIdentifiers` |
| Requirement workbook | `IntegrationAPITool/artifacts/requirement_doc/AlternateIdentifiers.xlsx` |
| JIRA story | `LIQSC-63867` |
| Workbook sheets | `GetById` |
| JIRA status | Story provided; attachment is required after plan review |

## Requirement Summary

The workbook defines a query integration for alternate identifiers:

- Integration class: `LiqAPIAlternateIdentifiersQueryIntegration`
- Response class: `LiqAPIAlternateIdentifiersIntegrationAsReturnValue`
- Package: `com.finastra.liq.api.rest.executable.fee`
- PCP: `N`
- Input object: `objectIdentifier`
  - `objectType` (`String`, required)
  - `identfierType` (`String`, required; supports `id` and `alias` for Outstanding and Outstanding Transaction)
  - `identifierValue` (`String`, required)
- Output: success and message fields, schedule information, and a list of alternate identifiers.
  - `success` (`String`, required)
  - `Message` (`String`, required)
  - `hasSchedule` (`Boolean`, required)
  - `scheduleType` (`String`, required)
  - Repeated `objectIdentifier` entries containing `objectType`, `identfierType`, and `identifierValue`

The generated implementation must preserve the workbook’s validation intent, including supported object-type values (`OST` and `LNID`), the requirement that the input identifier type and value identify one object, and the rule that returned identifiers include the supplied identifier. When `hasSchedule` is true, `scheduleType` is returned; when false, it is omitted.

## Planned Workflow

1. Read the `GetById` worksheet and normalize its input/output attribute metadata.
2. Confirm the query endpoint, request/response model conventions, naming conventions, and existing SOAP/API function mappings used by the repository.
3. Generate the query integration and supporting request/response artifacts using the repository’s lending API generation conventions.
4. Map the nested `objectIdentifier` structure and repeated output entries without changing the workbook’s field names or semantics.
5. Apply the documented enum/value and conditional validation rules to request and response handling.
6. Add or update focused integration coverage for the query request, response mapping, required fields, repeated identifiers, and conditional schedule behavior.
7. Review generated files for package placement, class names, field spelling compatibility, serialization shape, and consistency with neighboring lending APIs.
8. Decide whether the implementation is ready for developer approval before any code generation is executed.

## Planned Artifacts

Subject to developer approval of this plan, the implementation phase is expected to produce:

- Query integration class for `AlternateIdentifiers`.
- Request and response model classes for the nested identifier structure.
- Query integration test coverage and representative request/response JSON.
- Any repository-required registration or metadata updates discovered during the implementation review.

The plan-only phase must not modify source code, generate implementation classes, or run compile/test commands.

## Dependencies and Assumptions

- Existing LoanIQ lending REST query integration templates and shared serialization utilities are available.
- Existing repository conventions determine the endpoint path and SOAP function mapping; these must be verified rather than inferred from the workbook alone.
- The workbook’s `identfierType` spelling is intentional input metadata and must be reconciled with the output `identifierType`/`objectIdentifier` metadata during review without silently changing the external contract.
- No new third-party dependency is expected.

## Risks and Review Checkpoints

- **Field-name inconsistency:** `identfierType` is misspelled in input metadata while output metadata uses `objectIdentifier`; confirm the API contract before generation.
- **Nested/repeated output:** Verify list serialization and preservation of all unique identifiers.
- **Conditional response fields:** Verify omission of `scheduleType` when `hasSchedule` is false.
- **Enum values:** Confirm that `OST` and `LNID` are represented as the expected API enum/code values.
- **Endpoint mapping:** Confirm the existing SOAP/API function and REST path before implementation.
- **Package placement:** Confirm whether the workbook package is authoritative or whether the repository has a newer package convention.

## Go/No-Go Decision

**Go for developer review, not for implementation yet.** The workbook contains sufficient metadata to review the query design, but implementation should proceed only after the endpoint/SOAP mapping, identifier field naming, and conditional output behavior are confirmed against existing repository patterns.

## JIRA-Ready Summary

Plan prepared for `LIQSC-63867` for the `AlternateIdentifiers` query API. The proposed implementation covers required alternate-identifier input, nested/repeated identifier output, schedule metadata, validation rules, generated models/integration, and focused integration tests. Developer approval is required before code generation.
