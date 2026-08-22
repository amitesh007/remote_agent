---
name: lending-query-api-junit-generator
description: 'JUnit5 integration test generator specifically for LoanIQ Query (GET) API operations. Works with OR without a requirement specification spreadsheet. When a spreadsheet is provided, generates tests for all attributes from the GetByID sheet (100% coverage) AND inspects the LiqAPIQuery<entity>Integration class hierarchy. When no spreadsheet is provided, inspects the existing LiqAPIQuery<entity>Integration class and all its parent classes to generate comprehensive tests. Entity-name is supplied by the GitHub Action named lending-api-junit-generator. NEVER modifies actual API implementation classes — only Query IntegrationTest classes are written.'
---

# LoanIQ Query API JUnit Generator

> **Purpose**: Generate a complete `LiqAPIQuery{BusinessObject}IntegrationTest extends BaseTestLoanIQ` class for the LoanIQ REST API **Query (GET)** operation only, achieving maximum test coverage using real DB-backed integration patterns.
>
> **Supported Operation**: **Query only**. For Create, Update, or Delete test generation, use the corresponding skill (`lending-create-api-junit-generator`, `lending-update-test-api`, `lending-delete-api-junit-generator`).
>
> **Two Modes of Operation**:
> - **Specification Mode** (spreadsheet provided): Parse all attributes from the **GetByID sheet** following `lending-query-test-api` skill instructions, generate tests for every attribute, PLUS inspect the `LiqAPIQuery{BusinessObject}Integration` class and all its parent classes for supplemental test cases.
> - **Code-Inspection Mode** (no spreadsheet): Inspect the `LiqAPIQuery{BusinessObject}Integration` class and all its parent classes to derive test cases from field definitions, `@LiqAPIFieldMapper` annotations, validators, and business rules. Entity-name is provided by the GitHub Action `lending-api-junit-generator`. If entity-name is not provided, skip JUnit generation entirely.

---

## Pre-Flight Check — Specification Sheet Detection

**BEFORE doing anything else**, determine which mode to run:

```
IS a specification spreadsheet path provided in the prompt?
  ├─ YES → SPECIFICATION MODE
  │         Step A: Parse GetByID sheet using lending-query-test-api script pipeline
  │         Step B: ALSO run Class-Hierarchy Inspection for supplemental tests
  │         Step C: Generate tests combining both sources
  └─ NO  → CODE-INSPECTION MODE
            Step A: Check if entity-name was provided by GitHub Action 'lending-api-junit-generator'
            Step B: IF entity-name NOT provided → STOP — do NOT generate any JUnit class
            Step C: IF entity-name IS provided → run Class-Hierarchy Inspection only

NOTE: If any operation other than 'query' is specified → STOP and redirect to the correct skill.
```

---

## When to Use

Use `lending-query-api-junit-generator` when:
- Generating JUnit5 integration test classes for the LoanIQ **Query (GET) API operation only**
- You have OR do NOT have a requirement spreadsheet
- Entity-name is known (provided in prompt or by `lending-api-junit-generator` GitHub Action)
- You need real DB-backed integration tests (no mocks)

DO NOT use this skill for:
- Create test classes → use `lending-create-api-junit-generator`
- Update test classes → use `lending-update-test-api`
- Delete test classes → use `lending-delete-api-junit-generator`
- Generating the Query API implementation class itself → use `lending-query-api`
- **Any modification to actual API implementation classes** — ONLY `LiqAPIQuery{BusinessObject}IntegrationTest` classes may be written

---

## Required Inputs

| # | Input | Required? | Description |
|---|---|---|---|
| 1 | **Business Object (entity-name)** | **Mandatory** | Pascal-case name of the entity (e.g., `Deal`, `Facility`, `LoanDrawdown`). Provided in prompt OR by `lending-api-junit-generator` GitHub Action. If absent → skip generation. |
| 2 | **Operation** | **Fixed = `query`** | This skill only supports the `query` operation. If any other operation is specified, stop and redirect to the appropriate skill. |
| 3 | **Specification Spreadsheet Path** | Optional | Full path to `.xlsx` file. If absent → Code-Inspection Mode. |

### If entity-name is missing:

```
To generate the Query Integration test class, I need:

1. Business Object Name (entity-name) — Pascal-case (e.g., Deal, Facility, LoanDrawdown).
   This may be provided by the 'lending-api-junit-generator' GitHub Action.
   If not available, JUnit generation will be skipped.

2. Specification Spreadsheet Path — optional. If not provided, tests will be
   derived by inspecting the existing LiqAPIQuery<entity>Integration class and its parent classes.
```

If entity-name is not provided and no GitHub Action supplies it → **skip JUnit generation, do not create any file**.

If an operation other than `query` is specified → **stop and inform the user** to use the appropriate skill.

---

## Operation

This skill supports **Query only**:

| Operation | Integration Class | Test Class |
|---|---|---|
| `query` (**only**) | `LiqAPIQuery{BusinessObject}Integration` | `LiqAPIQuery{BusinessObject}IntegrationTest` |

---

## How to Run

```text
#lending-query-api-junit-generator Business Object is '{BusinessObject}'. [Specification spreadsheet path: '{SpreadsheetPath}']
```

Spreadsheet path is optional. Omit it to run in Code-Inspection Mode.

> **Note**: The operation is always `query`. If you need tests for create/update/delete, use the corresponding skill.

---

## Output Format

Test class location:
```text
LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/LiqAPIQuery{BusinessObject}IntegrationTest.java
```

JSON payload location (generated if missing):
```text
LoanIQ/test-resources/json/{domain}/Query{BusinessObject}Integration.json
```

The test class:
- Extends `BaseTestLoanIQ`
- Uses `@TestMethodOrder(MethodOrderer.OrderAnnotation.class)`
- **If test class already exists**: append-only — find the last `@Order(N)` value, start new tests from `@Order(N+1)`. NEVER modify existing test methods.
- **If test class does not exist**: create it fresh from `@Order(1)`
- Generates a coverage report `lending-query-api-junit-generator.md` in the same folder

---

## Constraint Categories (in priority order)

**Primary — Test Constraints**:
- Integration tests ONLY — NO Mockito, NO mocks, NO stubs, NO faked responses
- Every test exercises a real DB round-trip via `invokeApiInterface()` or `callBasicExecute()`
- **STRICTLY: NEVER modify any actual API implementation class** — only API Test classes may be created or updated

**Secondary — Spreadsheet Processing Constraints** (Specification Mode only):
- Use the provided PowerShell scripts to extract and parse spreadsheet contents
- Try all scripts sequentially — NEVER stop if the first script fails
- Fallback order: `extract-query-attributes.ps1` → `extract-query-attributes-fallback.ps1` → `read-spreadsheet-raw.ps1`

**Secondary — Codebase Constraints**:
- All referenced classes, methods, and enum constants MUST be verified to exist before use
- Ensure zero compilation errors in generated test methods

**MANDATORY — Row/Source Comment on Every Test Method:**
- If from spreadsheet: `// Spreadsheet row: {rowNumber} — {ATTRIBUTE_FIELD_NAME}`
- If from class inspection: `// Source: {ClassName}.java — field: {fieldName}`
- This comment MUST appear on the line immediately above the `@Test` annotation

**MANDATORY — Debug Logs in Every Test Method:**
- Positive tests: `LOG.debug("Testing {description}");`
- Negative tests: `LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());`

**MANDATORY — Error Message Assertion Block for ALL False Responses:**
For **every** test method where the response failure is expected, after `assertEquals("false", basicExecuteOutput.getSuccess())` or equivalent, immediately include:
```java
basicExecuteOutput.getAPIMessages().forEach(message -> {
    if (message instanceof LiqAPIExceptionMessage) {
        LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
        LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
        assertEquals("{specific expected error message}", ((LiqAPIExceptionMessage) message).getMessage());
    }
});
```

> **Reference implementations to read before generating any test**:
> - `LiqAPICreateConsolidatedCustomerIntegrationTest` — canonical error message assertion patterns
> - `LiqAPIUpdateConsolidatedCustomerIntegrationTest` — canonical update patterns
> - Any other existing tests referenced in `lending-query-test-api` skill

---

## Mode Decision Logic

```
HAS SpreadsheetPath?
  ├─ YES → SPECIFICATION MODE
  │         ├─ Run GetByID sheet parsing pipeline (Step 1 below)
  │         ├─ Generate tests for all GetByID attributes
  │         └─ ALSO run Class-Hierarchy Inspection (Step 3) for supplemental tests
  └─ NO  → CODE-INSPECTION MODE
            ├─ Skip spreadsheet steps entirely
            └─ Run Class-Hierarchy Inspection ONLY (Step 3)
```

---

## Step 1: Parse Requirement Spreadsheet (Specification Mode only)

All scripts are located at: `.github/skills/lending-query-api-junit-generator/scripts/`

### Primary extraction:
```powershell
.\scripts\extract-query-attributes.ps1 -ExcelFilePath "{SpreadsheetPath}" -SheetName "GetByID"
```

### Fallback (if primary fails):
```powershell
.\scripts\extract-query-attributes-fallback.ps1 -ExcelFilePath "{SpreadsheetPath}"
```

### Last resort (if fallback fails):
```powershell
.\scripts\read-spreadsheet-raw.ps1 -ExcelFilePath "{SpreadsheetPath}"
```

> **IMPORTANT**: Do NOT stop if the first script fails. Try all scripts sequentially. Continue with whatever attribute data is available.

### Spreadsheet Column Reading

For every row in the GetByID/GetById sheet:
- Read `ATTRIBUTE_FIELD_NAME` → output field name for test generation
- Read `ATTRIBUTE_DESCRIPTION` → generate description-based test cases
- Include comment: `// Spreadsheet row: {rowNumber} — {ATTRIBUTE_FIELD_NAME}`

**If ATTRIBUTE_DESCRIPTION is BLANK**: generate only the basic JUnit test (`assertNotNull`) for that attribute.

**If ATTRIBUTE_DESCRIPTION has CONTENT**: generate basic test PLUS description-based test(s) covering:
- Computed/calculated field logic
- Format constraints
- Conditional display rules
- Code table value validation
- Relational field consistency
- Derived status correctness

---

## Step 2: Existing Test Class Check (MANDATORY)

1. Check `IntegrationAPITool/artifacts/temp_generated_class/` for `LiqAPIQuery{BusinessObject}IntegrationTest.java`.
2. If not there, check `LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/`.
3. If found: read it, find last `@Order(N)`, set `nextOrder = N + 1`. **DO NOT modify existing test methods.**
4. If not found: `nextOrder = 1` (new class).

---

## Step 3: Class-Hierarchy Inspection (MANDATORY in BOTH Modes)

After spreadsheet parsing (Specification Mode) or instead of it (Code-Inspection Mode), inspect the Query Integration class and all its parent classes.

### Steps

1. **Locate Query Integration class**: `LiqAPIQuery{BusinessObject}Integration.java` — search `LoanIQ/srcgen/` first, then `LoanIQ/src/`.
2. **Read the superclass** from the `extends` clause, then walk the full hierarchy up to (but not including) `Object`.
3. **For each class, extract:**
   - All fields annotated with `@LiqAPIFieldMapper`
   - Getter methods and their return types
   - `validate()` or `doValidate()` override methods (extract expected error messages)
   - `nonPrimitiveFieldMappings()`, `primitiveFieldMappings()`, `nonPrimitiveFieldCollectionMappings()`
   - `securityAccessSymbol()`, `isRest()`, `securityFunctionParent()`, `supportsAdditionalFields()`
   - `basicNew()`, `getJavaClass()`, `getStClass()`, `getStSuperclass()`
   - `returnType()`, `documentedReturnValues()`
4. **For each discovered field not already covered:** generate positive test (CREATE seed + QUERY, then assert field) + negative test if validation exists.
5. **Also locate**: `LiqAPICreate{BusinessObject}Integration.java` — needed for CREATE seed step in positive tests.

### Comment format for class-inspection tests:
`// Source: {ClassName}.java — field: {fieldName}`

### Reference Classes (MUST read before generating):
- `LiqAPICreateConsolidatedCustomerIntegrationTest.java`
- `LiqAPIUpdateConsolidatedCustomerIntegrationTest.java`
- All reference test classes listed in `lending-query-test-api` skill

---

## Step 4: Load Query Request Payload

> **MANDATORY:** If the JSON payload file does not exist, generate it before writing any test methods.

**Template reference**: `.github/skills/lending-query-api-junit-generator/templates/query-request-template.md`

**Expected JSON location**:
```
LoanIQ/test-resources/json/{domain}/Query{BusinessObject}Integration.json
```

Also check: `IntegrationAPITool/artifacts/temp_generated_class/`

If not found → generate from GetByID sheet attributes (Specification Mode) or from discovered Integration class fields (Code-Inspection Mode). Save to the correct path.

---

## Naming Conventions

| Role | Pattern | Example (`Deal`) |
|---|---|---|
| Query class | `LiqAPIQuery{BusinessObject}Integration` | `LiqAPIQueryDealIntegration` |
| Test class | `LiqAPIQuery{BusinessObject}IntegrationTest` | `LiqAPIQueryDealIntegrationTest` |
| Identifier class | `LiqAPI{BusinessObject}Identifier` | `LiqAPIDealIdentifier` |
| Response class | `LiqAPI{BusinessObject}IntegrationAsReturnValue` | `LiqAPIDealIntegrationAsReturnValue` |
| Create class (seed) | `LiqAPICreate{BusinessObject}Integration` | `LiqAPICreateDealIntegration` |
| Java package | `com.misys.liq.api.rest.executable.{domain}` | `com.misys.liq.api.rest.executable.deal` |
| Enum prefix | `QUERY_{BUSINESS_OBJECT_UPPER}_*` | `QUERY_DEAL_INTEGRATION` |
| Security symbol | `"Query{BusinessObject}Integration"` | `"QueryDealIntegration"` |

- Domain = lowercased business object name
- Operation is always **`Query`** (capitalized)

---

## Required Class Skeleton

```java
package com.misys.liq.api.rest.executable.{domain};

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
// Add additional imports based on codebase discovery
import java.util.List;
import java.util.Properties;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIQuery{BusinessObject}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPIQuery{BusinessObject}IntegrationTest.class);

    private LiqAPICreate{BusinessObject}Integration liqAPIData;
    private LiqAPIQuery{BusinessObject}Integration liqAPiDataQuery;
    private LiqAPIResponse basicExecuteOutput;
    private LiqAPIResponse basicExecuteQuery;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }
}
```

**IMPORTANT — Existing Test Class:**
- If `LiqAPIQuery{BusinessObject}IntegrationTest.java` already exists → READ it first
- Find the highest `@Order(N)` value
- All new `@Order` tests start from `N + 1`
- **DO NOT modify, delete, or reorder any existing test method**

---

## Test Generation Strategy

### Phase A: Input Validation Tests (negative, ordered from nextOrder)

```java
// Spreadsheet row: {rowNumber} — identifier   [or]   // Source: {ClassName}.java — field: identifier
@Test
@Order({nextOrder})
public void testQuery{BusinessObject}WithNullIdentifier() throws JsonProcessingException {
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
        LiqAPIQuery{BusinessObject}Integration.class);
    liqAPiDataQuery.get{Identifier}().setIdentifierValue(null);
    LOG.debug("Order {N} - Testing query with null identifier");
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    assertEquals("false", basicExecuteQuery.getSuccess());
    basicExecuteQuery.getAPIMessages().forEach(message -> {
        if (message instanceof LiqAPIExceptionMessage) {
            LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
            LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
            assertEquals("{specific expected error message}", ((LiqAPIExceptionMessage) message).getMessage());
        }
    });
}
```

Additional input validation tests (each with full error message assertion block):
- Invalid identifier type
- Invalid identifier value (e.g., `"TOOLNG"` → `"Value TOOLNG of field {fieldName} should have a maxSize of {N}."`)
- Empty identifier value
- Non-existent entity ID

### Phase B: Successful Query Tests — CREATE seed + QUERY

**Pattern 1 (Standard Entity — Deal, Facility, UpfrontFee):**

```java
// Spreadsheet row: {rowNumber} — {attributeName}
@Test
@Order({nextOrder})
public void testQuery{BusinessObject}Returns{AttributeName}() throws JsonProcessingException {
    // ── SEED: CREATE ────────────────────────────────────────────────────
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LOG.debug("Order {N} - Step 1: Creating {BusinessObject} for query seed");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());

    // ── QUERY ────────────────────────────────────────────────────────────
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
        LiqAPIQuery{BusinessObject}Integration.class);
    liqAPiDataQuery.get{Identifier}().setIdentifierType("id");
    liqAPiDataQuery.get{Identifier}().setIdentifierValue(
        ((LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteOutput.getResult()).get{IdField}());
    LOG.debug("Order {N} - Step 2: Querying {BusinessObject}");
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    assertEquals("true", basicExecuteQuery.getSuccess());

    // ── ASSERT ATTRIBUTE ─────────────────────────────────────────────────
    LiqAPI{BusinessObject}IntegrationAsReturnValue output =
        (LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteQuery.getResult();
    assertNotNull(output);
    assertNotNull(output.get{AttributeName}());
}
```

**Pattern 2 (Transaction — LoanDrawdown, LoanInterestPayment, LoanPrincipalPayment, LoanRepricing):**

```java
// Source: {ClassName}.java — field: {fieldName}
@Test
@Order({nextOrder})
public void testQuery{BusinessObject}Returns{AttributeName}() throws JsonProcessingException {
    // ── SEED: CREATE ────────────────────────────────────────────────────
    LiqAPICreate{BusinessObject}Integration liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqApiDataUtil.callBasicValidate(liqAPIDataCreate);
    LOG.debug("Order {N} - Step 1: Creating {BusinessObject} for query seed");
    LiqAPI{BusinessObject}IntegrationAsReturnValue outputCreate =
        (LiqAPI{BusinessObject}IntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqAPIDataCreate);
    assertNotNull(outputCreate.getTransactionId());

    // ── QUERY ────────────────────────────────────────────────────────────
    liqAPiDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
        LiqAPIQuery{BusinessObject}Integration.class);
    liqAPiDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPiDataQuery);
    LOG.debug("Order {N} - Step 2: Querying {BusinessObject}");
    List<LiqAPI{BusinessObject}IntegrationAsReturnValue> results =
        (List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPiDataQuery);
    assertFalse(results.isEmpty());
    assertNotNull(results.get(0).get{AttributeName}());
}
```

**Pattern 3 (Polymorphic Owner — MISCode, AdditionalFields):**
Uses `ownerIdentifier` with `ownerType`, `ownerIdentifierType`, `ownerIdentifierValue`.

### Phase C: Attribute Coverage Tests (from spreadsheet / class inspection)

| Attribute Type | Test Pattern |
|---|---|
| **Mandatory Primitive** | `assertNotNull(output.get{AttributeName}())` |
| **Optional Primitive** | verify getter accessible (may be null) |
| **Non-Primitive Single** | `assertNotNull(output.get{NestedObject}())` + verify sub-fields |
| **Non-Primitive Collection** | `assertNotNull(output.get{Collection}())` + `assertFalse(output.get{Collection}().isEmpty())` |

### Phase D: ATTRIBUTE_DESCRIPTION-Based Tests (MANDATORY — Specification Mode)

For every attribute with content in `ATTRIBUTE_DESCRIPTION`:
- Computed field → verify calculation logic
- Format constraint → verify format
- Conditional display → verify presence/absence based on condition
- Code table reference → verify value in valid set
- Derived status → verify status correctness

All description-based negative tests must include the full error message assertion block.

### Phase E: Method Coverage Tests (unordered, each with LOG.debug)

```java
@Test public void testSecurityAccessSymbol() throws JsonProcessingException {
    liqAPiDataQuery = getMainObjectFromJsonQuery(...);
    LOG.debug("Testing securityAccessSymbol on LiqAPIQuery{BusinessObject}Integration");
    assertEquals("Query{BusinessObject}Integration", liqAPiDataQuery.securityAccessSymbol());
}
@Test public void testBasicNew() {
    LOG.debug("Testing basicNew");
    assertNotNull(LiqAPIQuery{BusinessObject}Integration.clazz.basicNew());
}
@Test public void testIsRest() {
    LOG.debug("Testing isRest");
    assertEquals(true, LiqAPIQuery{BusinessObject}Integration.clazz.isRest());
}
@Test public void testNonPrimitiveFieldMappings() {
    LOG.debug("Testing nonPrimitiveFieldMappings");
    assertNotNull(LiqAPIQuery{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings());
}
@Test public void testPrimitiveFieldMappings() {
    LOG.debug("Testing primitiveFieldMappings");
    assertNotNull(LiqAPIQuery{BusinessObject}Integration.clazz.primitiveFieldMappings());
}
@Test public void testNonPrimitiveFieldCollectionMappings() {
    LOG.debug("Testing nonPrimitiveFieldCollectionMappings");
    assertNotNull(LiqAPIQuery{BusinessObject}Integration.clazz.nonPrimitiveFieldCollectionMappings());
}
@Test public void testSecurityFunctionParent() {
    LOG.debug("Testing securityFunctionParent");
    assertNotNull(LiqAPIQuery{BusinessObject}Integration.clazz.securityFunctionParent());
}
@Test public void testSupportsAdditionalFields() {
    LOG.debug("Testing supportsAdditionalFields");
    assertNotNull(LiqAPIQuery{BusinessObject}Integration.clazz.supportsAdditionalFields());
}
@Test public void testReturnType() {
    LOG.debug("Testing returnType");
    assertNotNull(LiqAPIQuery{BusinessObject}Integration.clazz.returnType());
}
```

### Phase F: Identifier Variation Tests

- One positive test per supported identifier type (id, name, alias, etc.)
- One test with invalid identifier type → failure with full error message assertion block
- One test with non-existent identifier value → failure with full error message assertion block

### Phase G: Class-Hierarchy-Derived Tests (BOTH Modes)

```java
// Source: {ClassName}.java — field: {fieldName}
@Test
public void testQuery{BusinessObject}{FieldName}FromClassInspection() throws JsonProcessingException {
    // ... CREATE seed + QUERY bootstrap ...
    LOG.debug("Testing {fieldName} discovered from class hierarchy inspection");
    assertNotNull(output.get{FieldName}());
}
```

---

## Compilation Safety Rules

1. **Never reference a class that does not exist** — verify via codebase discovery
2. **Never call a method that does not exist** — verify from actual source files
3. **Never modify any API implementation class** — only test class files
4. **Import all used classes** — complete import statements
5. **Match enum constant names exactly** — copy from `GeneralIntegrationMapping.java`
6. **All test methods declare** `throws JsonProcessingException`
7. **Always import `LogManager`** from `org.apache.logging.log4j.LogManager`
8. **`@Order` values are sequential and non-duplicated** — append from `lastOrder + 1`
9. **Never hardcode entity IDs** — always derive from CREATE step or `TestDataConstants`
10. **Never omit `setIdempotencyKey()`** when seeding data via CREATE

---

## Allowed APIs (Whitelist)

| Helper | Purpose |
|---|---|
| `getMainObjectFromJsonCreate(enum, Class)` | Bootstrap entity to query |
| `getMainObjectFromJsonQuery(enum, Class)` | Build query DTO |
| `LiqApiDataUtil.getObjectFromJson(enum, Class)` | Load DTO from JSON |
| `invokeApiInterface(liqAPIData)` | Single-commit DB round trip |
| `LiqApiDataUtil.callBasicValidate(liqAPIData)` | Input validation |
| `LiqApiDataUtil.callBasicExecute(liqAPIData)` | Execute and return response |
| `LiqApiDataUtil.generateIdempotencyKey()` + `setIdempotencyKey(...)` | Seed POST |
| `setIdentifierValue(...)` / `setIdentifierType(...)` | Target identifier |
| `getAPIMessages()` / `getSuccess()` / `getResult()` | Response assertions |
| `.clazz.nonPrimitiveFieldMappings()` / `.clazz.primitiveFieldMappings()` | Mapping coverage |
| `.clazz.nonPrimitiveFieldCollectionMappings()` | Collection mapping coverage |
| `securityAccessSymbol()` | Verify security symbol |
| `basicValidate()` / `basicExecute()` | Direct method calls |
| `LOG.debug(...)` | Debug logging (mandatory in every test) |
| `LOG.error(...)` | Error logging (mandatory in every negative test) |

**NEVER use:** Mockito, PowerMock, spies, stubbed responses, `@Mock`, `@InjectMocks`.

---

## Coverage Checklist

Before finalizing:

- [ ] Every mandatory output attribute has `assertNotNull` test
- [ ] Every optional attribute has getter accessibility test
- [ ] Every non-primitive collection attribute has `assertFalse(isEmpty())` test
- [ ] Every attribute with `ATTRIBUTE_DESCRIPTION` has description-based test
- [ ] Input validation tests cover: null, invalid type, invalid value, empty, non-existent
- [ ] Method coverage tests (9+) present with `LOG.debug`
- [ ] All identifier types have positive tests
- [ ] Invalid identifier tests have full error message assertion block
- [ ] Every test has source comment (row number or class field)
- [ ] Every test has `LOG.debug` or `LOG.error` statement
- [ ] All false-response tests have full error message assertion block
- [ ] JSON payload file exists (generated if missing)
- [ ] No actual API implementation classes were modified

---

## Don'ts

- No `Mockito.mock(...)`, `@Mock`, `mockStatic`, `spy`, or `@InjectMocks`
- No standalone getter/setter tests — field must be exercised through a full round-trip
- No hand-constructed response objects
- No hardcoded entity identifiers — always derive from CREATE step
- No tests depending on other tests (each is self-contained)
- **No modifications to any actual API implementation class**
- No test methods without source comment
- No test methods without debug log statements
- No skipping CREATE seed step for positive query tests

---

## Execution Workflow Summary

> **Scripts location**: `.github/skills/lending-query-api-junit-generator/scripts/`

```
0. PRE-FLIGHT: Detect mode
   ├─ SpreadsheetPath provided? → SPECIFICATION MODE
   └─ No SpreadsheetPath?
       ├─ entity-name from 'lending-api-junit-generator' GitHub Action? → CODE-INSPECTION MODE
       └─ No entity-name? → STOP — skip JUnit generation
   NOTE: If operation other than 'query' → STOP and redirect to correct skill

[SPECIFICATION MODE: Step 1]
1. extract-query-attributes.ps1 (+ fallback chain) → attribute list from GetByID sheet
   └─ NEVER stop if primary fails — try all three scripts sequentially

[BOTH MODES: Steps 2+]
2. EXISTING TEST CLASS CHECK
   ├─ Check temp: IntegrationAPITool/artifacts/temp_generated_class/
   ├─ Check repo: LoanIQ/test/.../executable/{domain}/
   ├─ IF FOUND → read, find last @Order(N), set nextOrder = N + 1 (NEVER modify existing)
   └─ IF NOT FOUND → nextOrder = 1

3. CLASS-HIERARCHY INSPECTION
   ├─ Read LiqAPIQuery{BusinessObject}Integration.java + all parent classes
   ├─ Also read LiqAPICreate{BusinessObject}Integration.java (for CREATE seed)
   ├─ Extract: @LiqAPIFieldMapper fields, all clazz methods, validators
   └─ Read reference classes:
       ├─ LiqAPICreateConsolidatedCustomerIntegrationTest.java
       └─ LiqAPIUpdateConsolidatedCustomerIntegrationTest.java

4. CODEBASE DISCOVERY
   ├─ Find: Query class, Create class, response class, enum constants, security symbol
   └─ Verify all class/method/enum references before generating

5. JSON PAYLOAD CHECK
   ├─ Read LoanIQ/test-resources/json/{domain}/Query{BusinessObject}Integration.json
   ├─ Read .github/skills/lending-query-api-junit-generator/templates/query-request-template.md
   └─ IF NOT FOUND → GENERATE from attributes/class fields → SAVE to correct path

6. GENERATE TEST METHODS
   ├─ Phase A: Input validation tests (negative, ordered from nextOrder)
   ├─ Phase B: Successful query tests with CREATE seed + QUERY (all 3 patterns as needed)
   ├─ Phase C: Attribute coverage tests (all GetByID attributes)
   ├─ Phase D: ATTRIBUTE_DESCRIPTION-based tests (Specification Mode)
   ├─ Phase E: Method coverage tests (unordered, with LOG.debug)
   ├─ Phase F: Identifier variation tests
   └─ Phase G: Class-hierarchy-derived tests

7. PLACE FILE at:
   C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ\test\com\misys\liq\api\rest\executable\{domain}\
   LiqAPIQuery{BusinessObject}IntegrationTest.java

8. RUN tests:
   .\scripts\run-query-tests.ps1 -TestClass "LiqAPIQuery{BusinessObject}IntegrationTest"

9. FIX failing tests iteratively:
   a. Analyze failure (compilation, assertion, runtime)
   b. Fix ONLY the failing test — never touch passing tests or implementation classes
   c. Re-run all; repeat until 100% pass

10. GENERATE gap report: lending-query-api-junit-generator.md (same folder as test class)
    Columns: S.No. | Attributes | Covered (True/False) | Reason for not covered
    - One row per attribute (from GetByID sheet or class inspection)
    - Covered=True if any test (existing or new) exercises that attribute
    - Covered=False + reason if no test exists
    - "Already covered in existing junit methods" if pre-existing test covers it

11. Verify coverage checklist

12. DONE — return: complete compilable test class + JSON payload (if generated) + gap report
```

---

## Script & Template Reference

| Resource | Path | Purpose |
|---|---|---|
| `extract-query-attributes.ps1` | `.github/skills/lending-query-api-junit-generator/scripts/` | Primary GetByID attribute extraction |
| `extract-query-attributes-fallback.ps1` | `.github/skills/lending-query-api-junit-generator/scripts/` | Fallback for non-standard formats |
| `read-spreadsheet-raw.ps1` | `.github/skills/lending-query-api-junit-generator/scripts/` | Raw dump for manual parsing |
| `run-query-tests.ps1` | `.github/skills/lending-query-api-junit-generator/scripts/` | Run generated test class |
| `move-test-file.ps1` | `.github/skills/lending-query-api-junit-generator/scripts/` | Move from temp to repo location |
| JSON template | `.github/skills/lending-query-api-junit-generator/templates/query-request-template.md` | Payload structure |
| JSON payloads | `LoanIQ/test-resources/json/{domain}/Query{BusinessObject}Integration.json` | Test data |
| Temp artifacts | `IntegrationAPITool/artifacts/temp_generated_class/` | Scaffolded objects |
| Reference test (Create) | `LiqAPICreateConsolidatedCustomerIntegrationTest.java` | Canonical error pattern |
| Reference test (Update) | `LiqAPIUpdateConsolidatedCustomerIntegrationTest.java` | Pattern reference |
| Final test location | `LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/` | Output path |
| Gap report | `lending-query-api-junit-generator.md` (same folder as test class) | Coverage report |

---

## Post Agent Run Modification

Use this prompt to **append new test cases** to an existing test class without modifying any existing code:

```
#lending-query-api-junit-generator Business Object is '<entity-name>'.
[Specification spreadsheet at: '<path>']
Strictly do not change any existing code in LiqAPIQuery<entity-name>IntegrationTest.
Add new test cases starting from the last junit method in the existing class.
For all generated test methods, add a comment with the spreadsheet row number (if from spreadsheet)
or the source class field name (if from class inspection).
Add negative test cases wherever applicable.
Also inspect LiqAPIQuery<entity-name>Integration and all its parent classes for additional test cases.
```

### Rules for Post-Run Modification

1. **Preserve existing code** — do NOT modify, delete, or reorder existing test methods
2. **Append-only** — start from `lastOrder + 1`
3. **GetByID sheet only** — read only the GetByID/GetById sheet from the spreadsheet
4. **Row/source comment MANDATORY** on every new test method
5. **Negative tests MANDATORY** for applicable attributes
6. **Full error message assertion block MANDATORY** for all false-response tests
7. **Gap report** — generate `lending-query-api-junit-generator.md` in the test package folder
