---
name: lending-delete-api-junit-generator
description: 'JUnit5 integration test generator specifically for LoanIQ Delete API operations. Works with OR without a requirement specification spreadsheet. When a spreadsheet is provided, generates tests for all attributes from the Delete sheet (100% coverage) AND inspects the LiqAPIDelete<entity>Integration class hierarchy. When no spreadsheet is provided, inspects the existing LiqAPIDelete<entity>Integration class and all its parent classes to generate comprehensive tests. Entity-name is supplied by the GitHub Action named lending-api-junit-generator. NEVER modifies actual API implementation classes — only Delete IntegrationTest classes are written.'
---

# Delete API JUnit Generator — Consolidated Skill

> **Purpose**: Generate a complete `LiqAPIDelete{BusinessObject}IntegrationTest extends BaseTestLoanIQ` class for the LoanIQ REST API **Delete** operation only, achieving maximum test coverage using real DB-backed integration patterns.
>
> **Supported Operation**: **Delete only**. For Create, Update, or Query test generation, use the corresponding skill (`create-api-junit-generator`, `lending-update-test-api`, `lending-query-test-api`).
>
> **Two Modes of Operation**:
> - **Specification Mode** (spreadsheet provided): Parse all attributes from the **Delete sheet** following `lending-delete-test-api` skill instructions, generate tests for every attribute, PLUS inspect the `LiqAPIDelete{BusinessObject}Integration` class and all its parent classes for supplemental test cases.
> - **Code-Inspection Mode** (no spreadsheet): Inspect the `LiqAPIDelete{BusinessObject}Integration` class and all its parent classes to derive test cases from field definitions, `@LiqAPIFieldMapper` annotations, validators, and business rules. Entity-name is provided by the GitHub Action `lending-api-junit-generator`. If entity-name is not provided, skip JUnit generation entirely.

---

## Pre-Flight Check — Specification Sheet Detection

**BEFORE doing anything else**, determine which mode to run:

```
IS a specification spreadsheet path provided in the prompt?
  ├─ YES → SPECIFICATION MODE
  │         Step A: Parse spreadsheet Delete sheet using lending-delete-test-api script pipeline
  │         Step B: ALSO run Class-Hierarchy Inspection for supplemental tests
  │         Step C: Generate tests combining both sources
  └─ NO  → CODE-INSPECTION MODE
            Step A: Check if entity-name was provided by GitHub Action 'lending-api-junit-generator'
            Step B: IF entity-name NOT provided → STOP — do NOT generate any JUnit class
            Step C: IF entity-name IS provided → run Class-Hierarchy Inspection only

NOTE: If any operation other than 'delete' is specified → STOP and redirect to the correct skill.
```

---

## Constraint Categories (in priority order)

**Primary — Test Constraints** (applies to generated Java test code only):
- Integration tests ONLY — NO Mockito, NO mocks, NO stubs, NO faked responses
- Every test exercises a real DB round-trip via `invokeApiInterface()` or `callBasicExecute()`
- **STRICTLY: NEVER modify any actual API implementation class** — only API Test classes (files ending in `IntegrationTest.java`) may be created or updated
- Every `@Test` method MUST execute the full 3-step bootstrap (CREATE → QUERY → DELETE) — no step may be skipped

**Secondary — Spreadsheet Processing Constraints** (Specification Mode only):
- Use the provided PowerShell scripts to extract and parse spreadsheet contents
- Scripts handle .xlsx internal XML parsing and column layout detection automatically
- Fallback order: `parse-delete-attributes.ps1` → `parse-delete-attributes-fallback.ps1` → `parse-via-excel-com.ps1`
- Only ask the user to manually provide attribute data if ALL fallback scripts fail

**Secondary — Codebase Constraints**:
- All referenced classes, methods, and enum constants MUST be verified to exist before use
- Ensure zero compilation errors in generated test methods

**Secondary — Coverage Constraints**:
- Every spreadsheet attribute must have at least one test case (Specification Mode)
- Every field discovered from class inspection must have at least one test case (Code-Inspection Mode)
- **MANDATORY:** For every "ATTRIBUTE_FIELD_NAME" column, generate an additional test case based on "ATTRIBUTE_DESCRIPTION"
- Mandatory fields get both positive and negative tests
- Optional fields get positive tests plus boundary/validation tests where applicable
- Primitive field mappings, non-primitive field mappings, and non-primitive collection mappings MUST all be covered

**MANDATORY — Row/Source Comment on Every Test Method:**
- If from spreadsheet: `// Spreadsheet row: {rowNumber} — {ATTRIBUTE_FIELD_NAME}`
- If from class inspection: `// Source: {ClassName}.java — field: {fieldName}`
- This comment MUST appear on the line immediately above the `@Test` annotation

**MANDATORY — Debug Logs in Every Test Method:**
- Positive tests: `LOG.debug("Testing {description}");`
- Negative tests: `LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());`

**MANDATORY — Error Message Assertion Block for ALL False Responses:**
For **every** test method where the delete response failure is expected, after `assertEquals("false", basicExecuteDelete.getSuccess())` (or equivalent), immediately include:
```java
basicExecuteDelete.getAPIMessages().forEach(message -> {
    if (message instanceof LiqAPIExceptionMessage) {
        LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
        LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
        assertEquals("{specific expected error message}", ((LiqAPIExceptionMessage) message).getMessage());
    }
});
```
Where `{N}` is the `@Order` value and `{specific expected error message}` is the exact validation error.

> **Reference implementations to read before generating any test**:
> - `LiqAPICreateConsolidatedCustomerIntegrationTest` — canonical error message assertion patterns
> - `LiqAPIUpdateConsolidatedCustomerIntegrationTest` — canonical update/delete patterns
> - Any other existing tests referenced in `lending-delete-test-api` skill

---

## When to Use

Use `lending-delete-api-junit-generator` when:
- Generating JUnit5 integration test classes for the LoanIQ **Delete API operation only**
- You have OR do NOT have a requirement spreadsheet
- Entity-name is known (provided in prompt or by `lending-api-junit-generator` GitHub Action)
- You need real DB-backed integration tests (no mocks)

DO NOT use this skill for:
- Create test classes → use `create-api-junit-generator`
- Update test classes → use `lending-update-test-api`
- Query/Get test classes → use `lending-query-test-api`
- Generating the API implementation class itself → use `lending-delete-api`
- **Any modification to actual API implementation classes** — ONLY `LiqAPIDelete{BusinessObject}IntegrationTest` classes may be written

---

## Required Inputs

| # | Input | Required? | Description |
|---|---|---|---|
| 1 | **Business Object (entity-name)** | **Mandatory** | Pascal-case name of the entity (e.g., `UpfrontFee`, `Deal`). Provided in prompt OR by `lending-api-junit-generator` GitHub Action. If absent → skip generation. |
| 2 | **Operation** | **Fixed = `delete`** | This skill only supports the `delete` operation. If any other operation is specified, stop and redirect to the appropriate skill. |
| 3 | **Specification Spreadsheet Path** | Optional | Full path to `.xlsx` file. If absent → Code-Inspection Mode. |

### If entity-name is missing:

```
To generate the Delete Integration test class, I need:

1. Business Object Name (entity-name) — Pascal-case (e.g., UpfrontFee, Deal, Facility).
   This may be provided by the 'lending-api-junit-generator' GitHub Action.
   If not available, JUnit generation will be skipped.

2. Specification Spreadsheet Path — optional. If not provided, tests will be
   derived by inspecting the existing LiqAPIDelete<entity>Integration class and its parent classes.
```

If entity-name is not provided and no GitHub Action supplies it → **skip JUnit generation, do not create any file**.

If an operation other than `delete` is specified → **stop and inform the user** to use the appropriate skill.

---

## Operation

This skill supports **Delete only**:

| Operation | Integration Class | Test Class |
|---|---|---|
| `delete` (**only**) | `LiqAPIDelete{BusinessObject}Integration` | `LiqAPIDelete{BusinessObject}IntegrationTest` |

Special Cancel-as-Delete cases (e.g., LoanRepricing, LoanInterestPayment):

| Business Object | Delete Class | Test Class |
|---|---|---|
| LoanRepricing | `LiqAPICancelLoanRepricing` | `LiqAPICancelLoanRepricingIntegrationTest` |
| LoanInterestPayment | `LiqAPICancelInterestPayment` | `LiqAPICancelInterestPaymentIntegrationTest` |

---

## How to Run

```text
#lending-delete-api-junit-generator Business Object is '{BusinessObject}'. [Specification spreadsheet path: '{SpreadsheetPath}']
```

Spreadsheet path is optional. Omit it to run in Code-Inspection Mode.

> **Note**: The operation is always `delete`. If you need tests for create/update/query, use the corresponding skill.

---

## Output Format

Test class location:
```text
LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/LiqAPIDelete{BusinessObject}IntegrationTest.java
```

JSON payload location (generated if missing):
```text
LoanIQ/test-resources/json/{domain}/Delete{BusinessObject}Integration.json
```

The test class:
- Extends `BaseTestLoanIQ`
- Uses `@TestMethodOrder(MethodOrderer.OrderAnnotation.class)`
- **If test class already exists**: append-only — find the last `@Order(N)` value, start new tests from `@Order(N+1)`. NEVER modify existing test methods.
- **If test class does not exist**: create it fresh from `@Order(1)`

---

## Mode Decision Logic

```
HAS SpreadsheetPath?
  ├─ YES → SPECIFICATION MODE
  │         ├─ Run Delete sheet parsing pipeline (Steps 1-3 below)
  │         ├─ Generate tests for all Delete sheet attributes
  │         └─ ALSO run Class-Hierarchy Inspection (Step 4) for supplemental tests
  └─ NO  → CODE-INSPECTION MODE
            ├─ Skip spreadsheet steps entirely
            └─ Run Class-Hierarchy Inspection ONLY (Step 4)
```

---

## Spreadsheet Processing Rules (Specification Mode only)

> Skip entirely if no spreadsheet path is provided.

All scripts are located at: `.github/skills/lending-delete-api-junit-generator/scripts/`

### Script 1: Extract the Spreadsheet
```powershell
.\scripts\extract-spreadsheet.ps1 -SpreadsheetPath "{SpreadsheetPath}"
```

### Script 2: Find the Delete Sheet
```powershell
.\scripts\find-delete-sheet.ps1 -ExtractedPath "{ExtractedPath}"
```
If no Delete sheet found → stop and ask user for valid spreadsheet.

### Script 3: Parse All Delete Attributes
```powershell
.\scripts\parse-delete-attributes.ps1 -ExtractedPath "{ExtractedPath}" -SheetFile "{SheetFile}"
```

### Script 3a (Fallback):
```powershell
.\scripts\parse-delete-attributes-fallback.ps1 -ExtractedPath "{ExtractedPath}" -SheetFile "{SheetFile}"
```

### Script 3b (Last Resort):
```powershell
.\scripts\parse-via-excel-com.ps1 -SpreadsheetPath "{SpreadsheetPath}" -SheetName "Delete"
```

**Fallback Decision:**
```
parse-delete-attributes.ps1 → SUCCESS: continue
                            → FAILURE: try parse-delete-attributes-fallback.ps1
                                → SUCCESS: continue
                                → FAILURE: try parse-via-excel-com.ps1
                                    → SUCCESS: continue
                                    → FAILURE: ask user to provide attributes manually
```

### Attribute Data Interpretation
- `FieldName` — JSON/Java field name (maps to `ATTRIBUTE_FIELD_NAME`)
- `DataType` — String, Integer, Number, Boolean, Date, Enum, List, Object
- `Required` — Y (mandatory), N (optional), CR (conditionally required)
- `Description` — business rules, defaults, constraints, validation info (maps to `ATTRIBUTE_DESCRIPTION`)
- `Category` — grouping
- `DefaultValue` — default if field omitted
- `MappingType` — Primitive, NonPrimitive, NonPrimitiveCollection

**CRITICAL:** For every spreadsheet row:
- Read `ATTRIBUTE_FIELD_NAME` → field name for test generation
- Read `ATTRIBUTE_DESCRIPTION` → generate description-based test cases
- Include comment: `// Spreadsheet row: {rowNumber} — {ATTRIBUTE_FIELD_NAME}`

---

## Class-Hierarchy Inspection (MANDATORY in BOTH Modes)

After spreadsheet parsing (Specification Mode) or instead of it (Code-Inspection Mode), inspect the Delete Integration class and all its parent classes.

### Steps

1. **Locate Delete Integration class**: `LiqAPIDelete{BusinessObject}Integration.java` (or `LiqAPICancel{BusinessObject}.java` for cancel-as-delete) — search in `LoanIQ/srcgen/` first, then `LoanIQ/src/`.

2. **Read the superclass**: Read the `extends` clause and open that file.

3. **Walk the full hierarchy** up to (but not including) `Object`.

4. **For each class, extract:**
   - All fields annotated with `@LiqAPIFieldMapper`
   - Setter methods and parameter types
   - `validate()` or `doValidate()` override methods (extract expected error messages)
   - `nonPrimitiveFieldMappings()`, `primitiveFieldMappings()`, `securityAccessSymbol()`
   - `isRest()`, `securityFunctionParent()`, `supportsAdditionalFields()`, `basicNew()`, `getStClass()`

5. **For each discovered field not already covered by spreadsheet:**
   - Positive test: full 3-step bootstrap (CREATE → QUERY → DELETE) with valid value → success
   - Negative test if mandatory: full 3-step bootstrap with null/invalid value → failure with `assertEquals` on error message
   - Invalid value test if code table referenced

6. **Comment format for class-inspection tests:**
   `// Source: {ClassName}.java — field: {fieldName}`

7. **Also locate and inspect:**
   - `LiqAPICreate{BusinessObject}Integration.java` — needed for CREATE step in 3-step bootstrap
   - `LiqAPIQuery{BusinessObject}Integration.java` — needed for QUERY step in 3-step bootstrap
   - `LiqAPI{BusinessObject}IntegrationAsReturnValue.java` — needed for response assertions

### Reference Classes (MUST read before generating)
- `LiqAPICreateConsolidatedCustomerIntegrationTest.java`
- `LiqAPIUpdateConsolidatedCustomerIntegrationTest.java`
- All reference test classes listed in `lending-delete-test-api` skill

---

## Class Name Convention

| Role | Pattern | Example (`UpfrontFee`) |
|---|---|---|
| Delete integration class | `LiqAPIDelete{BusinessObject}Integration` | `LiqAPIDeleteUpfrontFeeIntegration` |
| Test class | `LiqAPIDelete{BusinessObject}IntegrationTest` | `LiqAPIDeleteUpfrontFeeIntegrationTest` |
| Identifier class | `LiqAPI{BusinessObject}Identifier` | `LiqAPIUpfrontFeeIdentifier` |
| Response class | `LiqAPI{BusinessObject}IntegrationAsReturnValue` | `LiqAPIUpfrontFeeIntegrationAsReturnValue` |
| Create class (bootstrap) | `LiqAPICreate{BusinessObject}Integration` | `LiqAPICreateUpfrontFeeIntegration` |
| Query class (bootstrap) | `LiqAPIQuery{BusinessObject}Integration` | `LiqAPIQueryUpfrontFeeIntegration` |
| Java package | `com.misys.liq.api.rest.executable.{domain}` | `com.misys.liq.api.rest.executable.upfrontfee` |
| Enum prefix | `DELETE_{SCREAMING_SNAKE_CASE}_*` | `DELETE_UPFRONTFEE_TRANSACTION` |

- Domain = lowercased no-separator form of BusinessObject
- Operation is always **`Delete`** (capitalized)

---

## Codebase Discovery (mandatory before code generation)

Run discovery script:
```powershell
.\scripts\discover-codebase.ps1 -BusinessObject "{BusinessObject}" -CodebasePath "C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ"
```

Discovers: `LiqAPIDelete{BusinessObject}Integration` class, Create/Query classes, response class, `GeneralIntegrationMapping` DELETE_*/CREATE_*/QUERY_* enum constants, security symbol, package path, identifier pattern, If-Match requirements.

---

## JSON Delete Request Payload

> **MANDATORY:** If the JSON payload file does not exist, generate it before writing any test methods.

**Template reference**: `.github/skills/lending-delete-api-junit-generator/templates/json-delete-request.md`

**Expected JSON location**:
```
LoanIQ/test-resources/json/{domain}/Delete{BusinessObject}Integration.json
```

**If file does not exist**: generate from Delete sheet attributes (Specification Mode) or from discovered `LiqAPIDelete{BusinessObject}Integration` class fields (Code-Inspection Mode). Save to the correct path.

Also check: `IntegrationAPITool/artifacts/temp_generated_class/` for newly scaffolded objects.

---

## Allowed APIs (whitelist)

| Helper | Purpose |
|---|---|
| `getMainObjectFromJsonCreate(enum, Class)` | Bootstrap entity to delete |
| `getMainObjectFromJsonQuery(enum, Class)` | Re-fetch for `updateTimeStamp` (If-Match) |
| `getMainObjectFromJsonDelete(enum, Class)` | Build delete DTO from JSON template |
| `invokeApiInterface(liqAPIData)` | Single-commit DB round trip |
| `LiqApiDataUtil.getObjectFromJson(enum, Class)` | Load any integration DTO from JSON |
| `LiqApiDataUtil.callBasicValidate(liqAPIData)` | Input validation |
| `LiqApiDataUtil.callBasicExecute(liqAPIData)` | Execute and return response |
| `LiqApiDataUtil.generateIdempotencyKey()` + `setIdempotencyKey(...)` | POST header |
| `setMatchUpdatedTimestamp(date)` | If-Match concurrency header |
| `getAPIMessages()` / `getSuccess()` / `getResult()` | Response assertions |
| `DateUtility.getDateAsFormattedString(date, "yyyy-MM-dd HH:mm:ss.S")` | Date formatting |
| `LiqAPIDelete{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings()` | Mapping coverage |
| `LiqAPIDelete{BusinessObject}Integration.clazz.primitiveFieldMappings()` | Mapping coverage |
| `liqAPiDataDelete.securityAccessSymbol()` | Security symbol verification |
| `LOG.debug(...)` | Debug logging (mandatory in every test) |
| `LOG.error(...)` | Error logging (mandatory in every negative test) |

**NEVER use:**
- `Mockito.mock(...)`, `@Mock`, `mockStatic`, `spy`, `@InjectMocks`, `PowerMock`
- Manually instantiated response objects
- Stubbed or faked responses
- **Modifications to any actual API implementation class**

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
public class LiqAPIDelete{BusinessObject}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPIDelete{BusinessObject}IntegrationTest.class);

    private LiqAPICreate{BusinessObject}Integration liqAPIData;
    private LiqAPIQuery{BusinessObject}Integration liqAPiDataQuery;
    private LiqAPIDelete{BusinessObject}Integration liqAPiDataDelete;
    private LiqAPIResponse basicExecuteOutput;
    private LiqAPIResponse basicExecuteQuery;
    private LiqAPIResponse basicExecuteDelete;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }
}
```

**IMPORTANT — Existing Test Class:**
- If `LiqAPIDelete{BusinessObject}IntegrationTest.java` already exists → READ it first
- Find the highest `@Order(N)` value in the file
- All new `@Order` tests start from `N + 1`
- **DO NOT modify, delete, or reorder any existing test method**

---

## Mandatory 3-Step Bootstrap (MUST appear in every @Test method)

> **STRICT RULE**: Every `@Test` method MUST execute all three steps in order. No step may be skipped or reordered.

### Pattern A: `invokeApiInterface` Pattern (Deal, UpfrontFee, ProductGuarantee, MISCode)

```java
// Spreadsheet row: {rowNumber} — {fieldName}   [or]   // Source: {ClassName}.java — field: {fieldName}
@Test
@Order({nextOrder})
public void testDelete{BusinessObject}{TestScenario}() throws JsonProcessingException {
    // ── STEP 1: CREATE ──────────────────────────────────────────────────────
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LOG.debug("Order {N} - Step 1: Creating {BusinessObject}");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());

    // ── STEP 2: QUERY ───────────────────────────────────────────────────────
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
        LiqAPIQuery{BusinessObject}Integration.class);
    liqAPiDataQuery.get{Identifier}().setIdentifierValue(
        ((LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteOutput.getResult()).get{IdField}());
    LOG.debug("Order {N} - Step 2: Querying {BusinessObject}");
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    // ── STEP 3: DELETE ──────────────────────────────────────────────────────
    liqAPiDataDelete = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.{DELETE_ENUM}.toString(),
        LiqAPIDelete{BusinessObject}Integration.class);
    liqAPiDataDelete.get{Identifier}().setIdentifierType("id");
    liqAPiDataDelete.get{Identifier}().setIdentifierValue(
        ((LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteOutput.getResult()).get{IdField}());
    ((List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) basicExecuteQuery.getResult()).forEach(p -> {
        String dateAsFormattedString = DateUtility.getDateAsFormattedString(
            p.getUpdateTimeStamp(), "yyyy-MM-dd HH:mm:ss.S");
        liqAPiDataDelete.setMatchUpdatedTimestamp(dateAsFormattedString);
    });
    // ── Mutate specific field under test ─────────────────────────────────
    liqAPiDataDelete.set{FieldName}({testValue});
    LOG.debug("Order {N} - Step 3: Deleting {BusinessObject} with {fieldName}={testValue}");
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("{true|false}", basicExecuteDelete.getSuccess());
    // If false — MANDATORY error message assertion:
    basicExecuteDelete.getAPIMessages().forEach(message -> {
        if (message instanceof LiqAPIExceptionMessage) {
            LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
            LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
            assertEquals("{specific expected error message}", ((LiqAPIExceptionMessage) message).getMessage());
        }
    });
}
```

### Pattern B: `callBasicExecute` Pattern (LoanDrawdown, LoanPrincipalPayment)

```java
// Source: {ClassName}.java — field: {fieldName}
@Test
@Order({nextOrder})
public void testDelete{BusinessObject}{TestScenario}() throws JsonProcessingException {
    // ── STEP 1: CREATE ──────────────────────────────────────────────────────
    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.basicValidate();
    LOG.debug("Order {N} - Step 1: Creating {BusinessObject}");
    LiqAPI{BusinessObject}IntegrationAsReturnValue outputCreate =
        (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIData.basicExecute();
    assertNotNull(outputCreate.getLoanTransactionId());

    // ── STEP 2: QUERY ───────────────────────────────────────────────────────
    LiqAPIQuery{BusinessObject}Integration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
        LiqAPIQuery{BusinessObject}Integration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    LOG.debug("Order {N} - Step 2: Querying {BusinessObject}");
    List<LiqAPI{BusinessObject}IntegrationAsReturnValue> queryOutput =
        (List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    assertFalse(queryOutput.isEmpty());

    // ── STEP 3: DELETE ──────────────────────────────────────────────────────
    LiqAPIDelete{BusinessObject}Integration liqAPIDataDelete = new LiqAPIDelete{BusinessObject}Integration();
    liqAPIDataDelete.setOutstandingTransactionIdentifier(new LiqAPIOutstandingTransactionIdentifier());
    liqAPIDataDelete.getOutstandingTransactionIdentifier().setIdentifierType(
        LiqAPIOutstandingTransactionIdentifier.OutstandingTransactionIdentifierType.transactionId.name());
    liqAPIDataDelete.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    // ── Mutate specific field under test ─────────────────────────────────
    liqAPIDataDelete.set{FieldName}({testValue});
    LOG.debug("Order {N} - Step 3: Deleting {BusinessObject} with {fieldName}={testValue}");
    LiqApiDataUtil.callBasicValidate(liqAPIDataDelete);
    LiqApiDataUtil.callBasicExecute(liqAPIDataDelete);
}
```

### Pattern C: Cancel-as-Delete Pattern (LoanRepricing, LoanInterestPayment)

```java
// Spreadsheet row: {rowNumber} — {fieldName}
@Test
@Order({nextOrder})
public void testCancel{BusinessObject}{TestScenario}() throws JsonProcessingException {
    // ── STEP 1: CREATE ──────────────────────────────────────────────────────
    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.basicValidate();
    LOG.debug("Order {N} - Step 1: Creating {BusinessObject}");
    LiqAPI{BusinessObject}IntegrationAsReturnValue outputCreate =
        (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIData.basicExecute();
    assertNotNull(outputCreate.getTransactionId());

    // ── STEP 2: QUERY ───────────────────────────────────────────────────────
    LiqAPIQuery{BusinessObject}Integration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
        LiqAPIQuery{BusinessObject}Integration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    LOG.debug("Order {N} - Step 2: Querying {BusinessObject}");
    List<LiqAPI{BusinessObject}IntegrationAsReturnValue> queryResults =
        (List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    assertFalse(queryResults.isEmpty());

    // ── STEP 3: CANCEL/DELETE ────────────────────────────────────────────────
    LiqAPICancel{BusinessObject} liqAPIDataCancel =
        (LiqAPICancel{BusinessObject}) LiqAPICancel{BusinessObject}.clazz.basicNew();
    liqAPIDataCancel.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPIOutstandingTransactionIdentifier identifier = new LiqAPIOutstandingTransactionIdentifier();
    identifier.setIdentifierType(
        LiqAPIOutstandingTransactionIdentifier.OutstandingTransactionIdentifierType.transactionId.name());
    identifier.setIdentifierValue(outputCreate.getTransactionId());
    liqAPIDataCancel.setOutstandingTransactionIdentifier(identifier);
    // ── Mutate specific field under test ─────────────────────────────────
    LOG.debug("Order {N} - Step 3: Cancelling {BusinessObject}");
    liqAPIDataCancel.basicValidate();
    liqAPIDataCancel.basicExecute();
}
```

---

## Test Generation Strategy

### Phase 0: Existing Class Check (MANDATORY first step)

1. Check if `LiqAPIDelete{BusinessObject}IntegrationTest.java` exists in `IntegrationAPITool/artifacts/temp_generated_class/`.
2. If not there, check `LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/`.
3. If found anywhere: read it, find last `@Order(N)`, set `nextOrder = N + 1`.
4. If not found: `nextOrder = 1`.

### Phase 1: Mandatory Field Validation Tests (negative, ordered)

For every `Required=Y` attribute — full 3-step bootstrap then set field to null/invalid:

```java
// Spreadsheet row: {rowNumber} — {fieldName}
@Test
@Order({nextOrder})
public void testDelete{BusinessObject}Without{FieldName}() throws JsonProcessingException {
    // ... full 3-step bootstrap ...
    liqAPiDataDelete.set{FieldName}(null);
    LOG.debug("Order {N} - Testing Delete {BusinessObject} without {fieldName}");
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("false", basicExecuteDelete.getSuccess());
    basicExecuteDelete.getAPIMessages().forEach(message -> {
        if (message instanceof LiqAPIExceptionMessage) {
            LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
            LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
            assertEquals("A value is required for field {fieldName}.", ((LiqAPIExceptionMessage) message).getMessage());
        }
    });
}
```

### Phase 2: Invalid Value Tests (negative, ordered)

For attributes with validation rules (code tables, length limits):

```java
// Spreadsheet row: {rowNumber} — {fieldName}
@Test
@Order({nextOrder})
public void testDelete{BusinessObject}WithInvalid{FieldName}() throws JsonProcessingException {
    // ... full 3-step bootstrap ...
    liqAPiDataDelete.set{FieldName}("TOOLNG");
    LOG.debug("Order {N} - Testing Delete {BusinessObject} with invalid {fieldName}");
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("false", basicExecuteDelete.getSuccess());
    basicExecuteDelete.getAPIMessages().forEach(message -> {
        if (message instanceof LiqAPIExceptionMessage) {
            LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
            LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
            assertEquals("Value TOOLNG of field {fieldName} should have a maxSize of {N}.", ((LiqAPIExceptionMessage) message).getMessage());
        }
    });
}
```

### Phase 3: Positive / Happy-Path Tests (unordered)

For every attribute — full 3-step bootstrap with valid value:

```java
// Spreadsheet row: {rowNumber} — {fieldName}
@Test
public void testDelete{BusinessObject}With{FieldName}() throws JsonProcessingException {
    // ... full 3-step bootstrap with valid field value ...
    LOG.debug("Testing Delete {BusinessObject} with valid {fieldName}");
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("true", basicExecuteDelete.getSuccess());
}
```

### Phase 4: ATTRIBUTE_DESCRIPTION-Based Tests (MANDATORY — Specification Mode)

For every attribute with content in `ATTRIBUTE_DESCRIPTION`, generate an additional test:
- Business rule → test validating that rule (full 3-step bootstrap)
- Constraints (min/max, format) → boundary/validation test
- Conditional behavior → conditional logic test
- Code table values → valid/invalid value tests
- If-Match / concurrency → timestamp tests

All description-based negative tests must include the full error message assertion block.

### Phase 5: If-Match / Timestamp Tests (if applicable)

```java
// Source: Delete concurrency control — If-Match timestamp
@Test
@Order({nextOrder})
public void testDelete{BusinessObject}WithoutIfMatch() throws JsonProcessingException {
    // ... steps 1 & 2 only, then delete without setting timestamp ...
    LOG.debug("Order {N} - Testing Delete {BusinessObject} without If-Match timestamp");
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("false", basicExecuteDelete.getSuccess());
    basicExecuteDelete.getAPIMessages().forEach(message -> {
        if (message instanceof LiqAPIExceptionMessage) {
            LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
            LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
            assertNotNull(exceptionMessage.getMessage());
        }
    });
}
```

### Phase 6: Identifier Variation Tests

- One positive test per supported identifier type
- One test with invalid identifier type → failure
- One test with non-existent identifier value → failure

### Phase 7: Class-Hierarchy-Derived Tests (BOTH Modes)

For fields discovered via class inspection not already covered by spreadsheet:

```java
// Source: {ClassName}.java — field: {fieldName}
@Test
public void testDelete{BusinessObject}{FieldName}FromClassInspection() throws JsonProcessingException {
    // ... full 3-step bootstrap with valid field value ...
    liqAPiDataDelete.set{FieldName}({validValue});
    LOG.debug("Testing {fieldName} discovered from class hierarchy inspection");
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("true", basicExecuteDelete.getSuccess());
}
```

### Phase 8: Post-Delete Verification Test

```java
// Mandatory: verify deleted entity is no longer queryable
@Test
public void testDeleted{BusinessObject}IsNotQueryable() throws JsonProcessingException {
    // ... full 3-step bootstrap (CREATE → QUERY → DELETE) ...
    LOG.debug("Testing that deleted {BusinessObject} is no longer queryable");
    assertEquals("true", basicExecuteDelete.getSuccess());
    // Re-query — assert entity no longer retrievable
}
```

---

## Mandatory Class-Mapping Coverage Tests

```java
@Test
public void testNonPrimitiveFieldMappings() {
    assertNotNull(LiqAPIDelete{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings());
}

@Test
public void testPrimitiveFieldMappings() {
    assertNotNull(LiqAPIDelete{BusinessObject}Integration.clazz.primitiveFieldMappings());
}

@Test
public void testSecurityAccessSymbol() throws JsonProcessingException {
    LiqAPIDelete{BusinessObject}Integration data = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.{DELETE_ENUM}.toString(),
        LiqAPIDelete{BusinessObject}Integration.class);
    assertEquals("Delete{BusinessObject}Integration", data.securityAccessSymbol());
}

@Test
public void testIsRest() {
    assertEquals(true, LiqAPIDelete{BusinessObject}Integration.clazz.isRest());
}

@Test
public void testSecurityFunctionParent() {
    assertNotNull(LiqAPIDelete{BusinessObject}Integration.clazz.securityFunctionParent());
}

@Test
public void testSupportsAdditionalFields() {
    assertNotNull(LiqAPIDelete{BusinessObject}Integration.clazz.supportsAdditionalFields());
}

@Test
public void testBasicNew() {
    assertNotNull(LiqAPIDelete{BusinessObject}Integration.clazz.basicNew());
}

@Test
public void testGetStClass() throws JsonProcessingException {
    LiqAPIDelete{BusinessObject}Integration data = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.{DELETE_ENUM}.toString(),
        LiqAPIDelete{BusinessObject}Integration.class);
    assertNotNull(data.getStClass());
}
```

---

## Compilation Safety Rules

1. **Never reference a class that does not exist** — verify via codebase discovery
2. **Never call a method that does not exist** — verify from actual source files
3. **Never modify any API implementation class** — only test class files
4. **Always perform full 3-step bootstrap** in every `@Test` method
5. **Never hardcode transaction IDs** — always derive from CREATE result
6. **Never hardcode `updateTimeStamp`** — always derive from QUERY result
7. **Import all used classes** — complete import statements
8. **Match enum constant names exactly** — copy from `GeneralIntegrationMapping.java`
9. **All test methods declare** `throws JsonProcessingException`
10. **Always import `LogManager`** from `org.apache.logging.log4j.LogManager`
11. **`@Order` values are sequential and non-duplicated** — append from `lastOrder + 1`
12. **Never skip the idempotency key** on CREATE steps that require it

---

## Coverage Checklist

Before finalizing:

- [ ] Every Required=Y attribute has null/missing negative test (with 3-step bootstrap)
- [ ] Every Required=Y attribute has valid positive test (with 3-step bootstrap)
- [ ] Every optional attribute has at least one positive test
- [ ] Every attribute with validation rules has invalid-value negative test
- [ ] Every attribute with description content has description-based test
- [ ] If-Match / timestamp tests present (if applicable)
- [ ] Identifier variation tests present
- [ ] Class-mapping coverage tests (8) present
- [ ] Post-delete verification test present
- [ ] All enum constants have at least one associated test
- [ ] Every test method has source comment (row number or class field)
- [ ] Every test method has LOG.debug or LOG.error statements
- [ ] All false-response tests have full error message assertion block
- [ ] JSON payload file exists (generated if missing)
- [ ] No actual API implementation classes were modified
- [ ] All tests use full 3-step bootstrap (CREATE → QUERY → DELETE)

---

## Don'ts

- **Never skip any of the 3 steps** — every `@Test` MUST call CREATE, then QUERY, then DELETE
- **Never reorder the 3 steps**
- **Never use a hardcoded transaction ID / identifier value** — always derive from CREATE result
- **Never use a hardcoded `updateTimeStamp`** — always derive from QUERY result
- No `Mockito.mock(...)`, `@Mock`, `mockStatic`, `spy`, or `@InjectMocks`
- No standalone getter/setter tests — field must be exercised through a full round-trip
- No hand-constructed response objects
- **No modifications to any actual API implementation class**
- No test methods without source comment
- No test methods without debug log statements
- Never delete data the test does not own

---

## Execution Workflow Summary

> **Scripts location**: `.github/skills/lending-delete-api-junit-generator/scripts/`

```
0. PRE-FLIGHT: Detect mode
   ├─ SpreadsheetPath provided? → SPECIFICATION MODE
   └─ No SpreadsheetPath?
       ├─ entity-name from 'lending-api-junit-generator' GitHub Action? → CODE-INSPECTION MODE
       └─ No entity-name? → STOP — skip JUnit generation
   NOTE: If any operation other than 'delete' is specified → STOP and redirect to the correct skill

[SPECIFICATION MODE: Steps 1-3]
1. extract-spreadsheet.ps1 → produces extracted XML folder
2. find-delete-sheet.ps1   → finds the Delete sheet XML (stop if not found)
3. parse-delete-attributes.ps1 (+ fallback chain) → structured attribute list from Delete sheet
   └─ IF ALL FAIL → ask user for manual attributes

[BOTH MODES: Steps 4+]
4. CLASS-HIERARCHY INSPECTION
   ├─ Read LiqAPIDelete{BusinessObject}Integration.java + all parent classes
   ├─ Read LiqAPICreate{BusinessObject}Integration.java (for CREATE bootstrap)
   ├─ Read LiqAPIQuery{BusinessObject}Integration.java (for QUERY bootstrap)
   ├─ Extract: @LiqAPIFieldMapper fields, setters, validate() methods, mappings, security symbol
   └─ Read reference classes:
       ├─ LiqAPICreateConsolidatedCustomerIntegrationTest.java
       └─ LiqAPIUpdateConsolidatedCustomerIntegrationTest.java

5. discover-codebase.ps1 → delete/create/query classes, response class, enum constants,
   security symbol, identifier pattern, If-Match requirements

6. JSON PAYLOAD CHECK
   ├─ Read LoanIQ/test-resources/json/{domain}/Delete{BusinessObject}Integration.json
   ├─ Read .github/skills/lending-delete-api-junit-generator/templates/json-delete-request.md
   ├─ Check IntegrationAPITool/artifacts/temp_generated_class/
   └─ IF JSON NOT FOUND → GENERATE from Delete sheet attributes/class fields → SAVE to correct path

7. EXISTING TEST CLASS CHECK
   ├─ Check IntegrationAPITool/artifacts/temp_generated_class/ for LiqAPIDelete{BusinessObject}IntegrationTest.java
   ├─ Check LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/ for LiqAPIDelete{BusinessObject}IntegrationTest.java
   ├─ IF FOUND → read file, find last @Order(N), set nextOrder = N + 1
   │             STRICT: do NOT modify any existing test method
   └─ IF NOT FOUND → nextOrder = 1 (new class)

8. GENERATE TEST METHODS
   ├─ Phase 1: Mandatory field negative tests (ordered, with 3-step bootstrap)
   ├─ Phase 2: Invalid value negative tests (ordered, with 3-step bootstrap)
   ├─ Phase 3: Positive happy-path tests (unordered, with 3-step bootstrap)
   ├─ Phase 4: ATTRIBUTE_DESCRIPTION-based tests (Specification Mode)
   ├─ Phase 5: If-Match / timestamp tests (if applicable)
   ├─ Phase 6: Identifier variation tests
   ├─ Phase 7: Class-hierarchy-derived tests
   ├─ Phase 8: Post-delete verification test
   └─ Mandatory: Class-mapping coverage tests (8)

9. PLACE FILE at:
   C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ\test\com\misys\liq\api\rest\executable\{domain}\
   LiqAPIDelete{BusinessObject}IntegrationTest.java

10. RUN tests → collect PASS/FAIL per method

11. FIX failing tests iteratively:
    a. Analyze failure (compilation, assertion, runtime)
    b. Fix ONLY the failing test — never touch passing tests or implementation classes
    c. Re-run all
    d. Repeat until 100% pass

12. GENERATE gap report: lending-delete-api-junit-generator.md (same folder as test class)
    Columns: S.No. | Attributes | Covered (True/False) | Reason for not covered
    - One row per attribute (from spreadsheet or class inspection)
    - Covered=True if any test (existing or new) exercises that attribute
    - Covered=False + reason if no test exists
    - "Already covered in existing junit methods" if pre-existing test covers it

13. Verify coverage checklist

14. DONE — return: complete compilable test class + JSON payload (if generated) + gap report
```

---

## Script & Template Reference

| Resource | Path | Purpose |
|---|---|---|
| `extract-spreadsheet.ps1` | `.github/skills/lending-delete-api-junit-generator/scripts/` | Extract .xlsx to XML |
| `find-delete-sheet.ps1` | `.github/skills/lending-delete-api-junit-generator/scripts/` | Find Delete worksheet |
| `parse-delete-attributes.ps1` | `.github/skills/lending-delete-api-junit-generator/scripts/` | Parse attribute rows (primary) |
| `parse-delete-attributes-fallback.ps1` | `.github/skills/lending-delete-api-junit-generator/scripts/` | Dynamic header detection fallback |
| `parse-via-excel-com.ps1` | `.github/skills/lending-delete-api-junit-generator/scripts/` | Excel COM fallback |
| `discover-codebase.ps1` | `.github/skills/lending-delete-api-junit-generator/scripts/` | Find classes, enums, symbols |
| JSON delete template | `.github/skills/lending-delete-api-junit-generator/templates/json-delete-request.md` | Payload structure |
| JSON payloads | `LoanIQ/test-resources/json/{domain}/Delete{BusinessObject}Integration.json` | Test data |
| Temp artifacts | `IntegrationAPITool/artifacts/temp_generated_class/` | Scaffolded objects |
| Reference test (Create) | `LiqAPICreateConsolidatedCustomerIntegrationTest.java` | Canonical error message pattern |
| Reference test (Update) | `LiqAPIUpdateConsolidatedCustomerIntegrationTest.java` | Pattern reference |
| Final test location | `LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/` | Output path |
| Gap report | `lending-delete-api-junit-generator.md` (same folder as test class) | Coverage report |

---

## Post Agent Run Modification

Use this prompt to **append new test cases** to an existing test class without modifying any existing code:

```
#lending-delete-api-junit-generator Business Object is '<entity-name>'.
[Specification spreadsheet at: '<path>']
Strictly do not change any existing code in LiqAPIDelete<entity-name>IntegrationTest.
Add new test cases starting from the last junit method in the existing class.
For all generated test methods, add a comment with the spreadsheet row number (if from spreadsheet)
or the source class field name (if from class inspection).
Add negative test cases wherever applicable.
Also inspect LiqAPIDelete<entity-name>Integration and all its parent classes for additional test cases.
Every generated test method must include the full 3-step bootstrap (CREATE -> QUERY -> DELETE).
```

### Rules for Post-Run Modification

1. **Preserve existing code** — do NOT modify, delete, or reorder existing test methods
2. **Append-only** — start from `lastOrder + 1`
3. **Delete sheet only** — read only the Delete sheet from the spreadsheet
4. **Row/source comment MANDATORY** on every new test method
5. **Full 3-step bootstrap MANDATORY** in every new test method
6. **Negative tests MANDATORY** for applicable attributes
7. **Full error message assertion block MANDATORY** for all false-response tests
8. **Gap report** — generate `lending-delete-api-junit-generator.md` in the test package folder