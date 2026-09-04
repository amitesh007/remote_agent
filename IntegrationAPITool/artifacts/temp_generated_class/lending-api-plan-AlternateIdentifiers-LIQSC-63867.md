# Lending API Implementation Plan: AlternateIdentifiers

## Request

- **JIRA story:** LIQSC-63867
- **Entity:** `AlternateIdentifiers`
- **Requirement workbook:** `IntegrationAPITool/artifacts/requirement_doc/AlternateIdentifiers.xlsx`
- **Available operation:** `GetById`

## API operation

Implement the query integration represented by `GetById`:

- Integration class: `LiqAPIAlternateIdentifiersQueryIntegration`
- Request class: `GetAlternateIdentifiersIntegration`
- Response class: `LiqAPIAlternateIdentifiersIntegrationAsReturnValue`
- Package: `com.finastra.liq.api.rest.executable.fee`

The query accepts an `objectIdentifier` containing the object type, identifier type,
and identifier value. It returns the success/message envelope and the matching
alternate identifiers.

## Request model

| Category | Field | Type | Required | Validation |
|---|---|---|---|---|
| `objectIdentifier` | `objectType` | `String` | Yes | Support `OST` (Outstanding) and `LNID` (Outstanding Transaction); use the bracketed code as the enum value. |
| `objectIdentifier` | `identfierType` | `String` | Yes | Support `id` and `alias` for both Outstanding and Outstanding Transaction; accept only one identifier with its corresponding object type. |
| `objectIdentifier` | `identifierValue` | `String` | Yes | Must contain the value represented by the selected identifier type. |

> Preserve the workbook spelling `identfierType` in the generated API contract unless
> the existing codebase provides an established mapping for the corrected spelling.

## Response model

### Envelope

- `success` (`String`, required): represents `true` or `false`.
- `Message` (`String`, required): list of API messages; distinguish errors and warnings
  in the response representation as required by the shared API conventions.

### Alternate identifier collection

Return the `objectIdentifier` collection with:

- `objectType` (`String`, required): supported values `OST` and `LNID`; return the
  same object type supplied in the request.
- `identfierType` (`String`, required): supported values `id` and `alias`.
- `identifierValue` (`String`, required): the identifier value for the returned type.

When an alias is supplied, include all unique identifiers associated with the
corresponding drawdown, including the identifier supplied in the request.

The response also includes the workbook-described `hasSchedule` (`Boolean`) and
`scheduleType` (`String`) fields. If `hasSchedule` is `true`, return `scheduleType`;
when it is `false`, omit `scheduleType`.

## Implementation steps

1. Confirm the existing query integration and response-envelope conventions in the
   LoanIQ REST module.
2. Add or update the query request model with the nested `objectIdentifier` fields
   and required validation.
3. Add or update the response model with the success/message envelope and nested
   alternate-identifier collection.
4. Implement the query integration using the existing SOAP/API translation pattern,
   preserving the requested object type and expanding aliases to unique identifiers.
5. Apply conditional schedule mapping: include `scheduleType` only when
   `hasSchedule` is true.
6. Add focused integration coverage for `OST` and `LNID`, `id` and `alias`, invalid
   combinations, alias expansion, success/error messages, and schedule omission.
7. Verify generated names, package placement, JSON serialization, and API documentation
   against the workbook before merging.

## Acceptance criteria

- Query integration and models use the names and package specified above.
- All required request and response fields are represented with the documented types.
- `OST`/`LNID` and `id`/`alias` rules are enforced.
- The requested object type is echoed in each returned identifier.
- Alias requests return the complete unique identifier set.
- `scheduleType` is conditional on `hasSchedule`.
- Success, error, and warning messages follow existing REST response conventions.
