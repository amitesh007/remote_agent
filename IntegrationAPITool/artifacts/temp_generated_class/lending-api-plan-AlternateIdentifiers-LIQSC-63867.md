# Plan Inputs

- **entityName:** `AlternateIdentifiers`
- **excelPath:** `/home/runner/work/remote_agent/remote_agent/IntegrationAPITool/artifacts/requirement_doc/AlternateIdentifiers.xlsx`
- **jiraStoryNumber:** `LIQSC-63867`
- **route summary:** Query-only `GetById` operation for alternate identifiers. The workbook defines the `objectIdentifier` input group (`objectType`, `identfierType`, and `identifierValue`) and a response containing `success`, `Message`, `hasSchedule`, `scheduleType`, and returned alternate-identifier values.

## Scope Analysis

- **Requested API types implied by the Excel sheet:** Query (`GetById`) only. No Create, Update, or Delete worksheets are present.
- **Expected generated artifacts:**
  - Query integration class `LiqAPIAlternateIdentifiersQueryIntegration`.
  - Response model `LiqAPIAlternateIdentifiersIntegrationAsReturnValue`.
  - Query/request model represented by `GetAlternateIdentifiersIntegration`.
  - Query integration test and any required JSON request/response fixtures, following the repository's generated-artifact layout.
- **Requirements to carry into generation:**
  - Required string inputs: `objectType`, `identfierType`, and `identifierValue`.
  - Support `OST` (Outstanding) and `LNID` (Outstanding Transaction) object types.
  - Support `id` and `alias` identifier types, with one identifier and matching object type per request.
  - Preserve the supplied object type in the response and return all unique identifiers, including the requested identifier.
  - Treat `hasSchedule` as a conditional response field: return `scheduleType` when true and omit it when false.
  - Return success and separately tagged error/warning messages.
- **Likely existing-file conflicts to review later:** Check for existing AlternateIdentifiers query classes, shared identifier models, package placement under `com.finastra.liq.api.rest.executable.fee`, and naming differences caused by the workbook's `identfierType` spelling before generation.

## Planned Workflow

1. **Read and normalize the requirement workbook.**
   - **Objective:** Confirm the single `GetById` worksheet, metadata, field names, required flags, and validation text.
   - **Relevant skill(s):** `lending-rest-excel-reader`.
   - **Required inputs:** The supplied `AlternateIdentifiers.xlsx` and `AlternateIdentifiers` entity name.
   - **Expected output:** A normalized query specification with the three required input fields and five response fields.

2. **Inspect the existing LoanIQ API conventions and hierarchy.**
   - **Objective:** Identify the correct base integration, request/response model conventions, package, route, and reusable identifier types.
   - **Relevant skill(s):** `lending-query-api`, `lending-liq-codegen`.
   - **Required inputs:** Normalized query specification and existing repository source tree.
   - **Expected output:** A conflict-checked mapping for the query integration, models, endpoint route, and fixture locations.

3. **Prepare the query implementation design.**
   - **Objective:** Map workbook validation rules to request validation, response serialization, conditional schedule behavior, and identifier enumeration behavior without changing source code during planning.
   - **Relevant skill(s):** `lending-query-api`.
   - **Required inputs:** Workbook field metadata and the inspected repository conventions.
   - **Expected output:** An implementation-ready query design and a list of required generated files.

4. **Define focused verification coverage for a later execution agent.**
   - **Objective:** Cover valid OST/LNID requests, id/alias identifiers, missing required fields, unsupported enum values, mismatched identifier/object combinations, response preservation, conditional `scheduleType`, and message tagging.
   - **Relevant skill(s):** `lending-query-test-api`.
   - **Required inputs:** Query design and workbook validation descriptions.
   - **Expected output:** A test and fixture checklist; no tests are executed in this plan-only phase.

5. **Developer review gate.**
   - **Objective:** Confirm the generated names, route, package, and interpretation of `identfierType` before execution.
   - **Relevant skill(s):** Developer review; execution would use `lending-liq-codegen`.
   - **Required inputs:** This plan and the source workbook.
   - **Expected output:** An explicit decision: **GO** to invoke a separate execution-capable agent for code generation, or **NO-GO** to stop and revise this plan. No code generation may begin without the GO decision.

## Risk and Blocker Checks

- **Excel file:** The workbook exists at the supplied absolute path and contains one readable `GetById` sheet.
- **ENTITY_NAME:** Explicitly supplied as `AlternateIdentifiers`; no inference is required.
- **Package/path mismatch:** The workbook specifies `com.finastra.liq.api.rest.executable.fee`, while the generated source tree may use a different package convention. Resolve this against neighboring query integrations before generation.
- **Field spelling:** The workbook uses `identfierType` in the input and `objectIdentifier` in some response category metadata. Preserve the API contract deliberately and verify whether the typo is an established public field or should be normalized by the execution agent.
- **Conditional response:** `hasSchedule`/`scheduleType` must be modeled and tested together so that false responses do not emit `scheduleType`.
- **Plan-only constraints:** This artifact contains planning only. No source code, generated code, compilation, test execution, or PR work is performed here.
- **JIRA handling:** `LIQSC-63867` was provided. Attachment status is **Local MCP Server unavailable** in this repository session; the plan remains generated locally.

## Plan Artifact

- **artifactFilePath:** `IntegrationAPITool/artifacts/temp_generated_class/lending-api-plan-AlternateIdentifiers-LIQSC-63867.md`
- **artifactWriteStatus:** Written
- **artifactNameConventionUsed:** `lending-api-plan-<ENTITY_NAME>-<JIRA_OR_NO-JIRA>.md`

## JIRA Story Attachment — LIQSC-63867

- **Plan summary:** Query-only AlternateIdentifiers API planning completed from the supplied workbook. The planned implementation covers OST/LNID object types, id/alias identifiers, required input validation, identifier preservation/enumeration, conditional schedule output, and separated error/warning messages.
- **Attachment outcome:** Local MCP Server unavailable. The markdown plan file was still generated at `IntegrationAPITool/artifacts/temp_generated_class/lending-api-plan-AlternateIdentifiers-LIQSC-63867.md`.
- **Action-ready summary:** Review the package and `identfierType` naming decisions, then choose GO for a separate code-generation agent or NO-GO to revise the plan.

## Developer Review Gate

The developer must review this plan against the workbook and existing source conventions. Before any code generation begins, explicitly choose one:

- **GO:** proceed with a separate execution-capable agent using this plan.
- **NO-GO:** stop and revise the plan.

## Definition of Done

- Plan produced from the `AlternateIdentifiers` workbook.
- One markdown plan artifact written under `IntegrationAPITool/artifacts/temp_generated_class`.
- JIRA status explicitly reported as Local MCP Server unavailable.
- No code generated.
- No PR created.
- No repository source-code files modified.

## Stop Condition

PLAN_READY: No execution performed by design.
