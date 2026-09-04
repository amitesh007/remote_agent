# Lending API Plan: AlternateIdentifiers

## Plan Inputs

- **Entity name:** `AlternateIdentifiers`
- **Requirement workbook:** `IntegrationAPITool/artifacts/requirement_doc/AlternateIdentifiers.xlsx`
- **JIRA story:** `LIQSC-63867`
- **Plan-only scope:** Produce an implementation plan only; do not modify source code, generate Java classes, run compilation, or run tests.

## Requirement Summary

The workbook describes a query API for alternate identifiers:

- **Integration class:** `LiqAPIAlternateIdentifiersQueryIntegration`
- **Response class:** `LiqAPIAlternateIdentifiersIntegrationAsReturnValue`
- **Package:** `com.finastra.liq.api.rest.executable.fee`
- **Input class:** `GetAlternateIdentifiersIntegration`
- **Input fields:** required `objectIdentifier.objectType`, `objectIdentifier.identfierType`, and `objectIdentifier.identifierValue`.
- Supported object types are Outstanding (`OST`) and Outstanding Transaction (`LNID`).
- Supported identifier types are `id` and `alias`. Exactly one identifier and its corresponding object type must be supplied.
- The response contains required `success`, `Message`, `hasSchedule`, `scheduleType`, and a list of `objectIdentifier` values (`objectType`, `identfierType`, and `identifierValue`).
- If `hasSchedule` is `true`, return `scheduleType`; if `false`, omit `scheduleType`.
- The response should include all unique identifiers for the requested object, including the identifier supplied in the request, and should preserve the input `objectType`.

## Planned Workflow

1. Read and normalize the workbook's input and output attribute definitions, retaining the spelling used by the requirement (`identfierType`) unless the existing codebase establishes a compatible canonical mapping.
2. Inspect existing LoanIQ REST query integrations, response models, object-identifier handling, enum/code-value conventions, validation, and package placement.
3. Identify the existing SOAP/API function or integration boundary needed to retrieve alternate identifiers. Confirm whether the workbook's `IN_SOAP_API = N` values require a new adapter or a repository-specific implementation path.
4. Define the request model and validation:
   - Require all three `objectIdentifier` fields.
   - Restrict `objectType` to `OST` or `LNID`.
   - Restrict `identfierType` to `id` or `alias`.
   - Enforce one identifier per request and reject mismatched or incomplete combinations.
5. Define the query integration and response mapping:
   - Return every unique identifier for the resolved object.
   - Preserve the requested object type.
   - Map `success` and messages consistently with neighboring APIs.
   - Apply the conditional `hasSchedule`/`scheduleType` rule.
6. Add or update OpenAPI/JSON examples and Javadocs according to the repository's established conventions.
7. Add focused query integration tests covering valid `OST` and `LNID` requests, `id` and `alias` inputs, identifier aggregation, object-type preservation, conditional schedule output, and validation/error responses.
8. Review generated and hand-written changes for naming, package, serialization, backward compatibility, and requirement traceability before implementation approval.

## Expected Implementation Artifacts

- Query request model for `GetAlternateIdentifiersIntegration`.
- Query integration implementation associated with `LiqAPIAlternateIdentifiersQueryIntegration`.
- Response model for `LiqAPIAlternateIdentifiersIntegrationAsReturnValue`.
- Object-identifier collection/mapping and validation support, reusing existing components where available.
- API documentation, JSON examples, and focused tests in the repository's established locations.

## Dependencies and Assumptions

- Existing query API base classes, validation utilities, response/message conventions, and SOAP/API client abstractions are available for reuse.
- The spelling `identfierType` is present in the source contract unless a compatibility-safe alias is required.
- The source system can return all unique identifiers for an Outstanding or Outstanding Transaction.
- `scheduleType` is meaningful only when `hasSchedule` is `true`; the implementation must omit it otherwise.

## Risks and Review Checkpoints

- **Source availability:** Confirm the underlying API function before implementation; the workbook marks the fields as not present in the SOAP API.
- **Contract spelling:** Confirm whether `identfierType` is an intentional public contract spelling and avoid an accidental breaking rename.
- **Identifier uniqueness:** Verify deduplication and retention of the requested identifier.
- **Conditional output:** Verify serialization omits `scheduleType` when `hasSchedule` is `false`.
- **Error semantics:** Align invalid object/identifier combinations and no-match behavior with existing LoanIQ API conventions.

The implementation should proceed only after the source integration point and contract conventions have been confirmed in a developer review.

## Go/No-Go Decision

**Go** when the existing integration boundary, response/message conventions, and identifier retrieval behavior are confirmed, and the conditional schedule requirement can be represented without breaking neighboring APIs. **No-go** if the source API cannot provide the required identifier set or if the public contract would require an incompatible rename.

## JIRA-Ready Summary

For **LIQSC-63867**, implement a query-only `AlternateIdentifiers` lending REST API using the supplied workbook. Add the request and response contracts, validate `OST`/`LNID` object types and `id`/`alias` identifiers, return all unique identifiers while preserving the requested object type, and conditionally return `scheduleType` based on `hasSchedule`. Reuse existing LoanIQ integration, validation, serialization, documentation, and test conventions. This artifact is a plan only; no source code, compilation, or tests were executed.

## Plan Artifact

- **Written to:** `IntegrationAPITool/artifacts/temp_generated_class/lending-api-plan-AlternateIdentifiers-LIQSC-63867.md`
- **JIRA status:** Plan prepared for `LIQSC-63867`; attachment must be handled through the configured JIRA MCP integration if available.
