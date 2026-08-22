---
name: lending-create-api-junit-generator
description: 'JUnit5 integration test generator specifically for LoanIQ Create API operations. Works with OR without a requirement specification spreadsheet. When a spreadsheet is provided, generates tests for all attributes from the Create sheet (100% coverage) AND inspects the LiqAPICreate<entity>Integration class hierarchy. When no spreadsheet is provided, inspects the existing LiqAPICreate<entity>Integration class and all its parent classes to generate comprehensive tests. Entity-name is supplied by the GitHub Action named lending-api-junit-generator. NEVER modifies actual API implementation classes — only Create IntegrationTest classes are written.'
---

# Universal API JUnit Generator — Consolidated Skill

> **Purpose**: Generate a complete `LiqAPICreate{BusinessObject}IntegrationTest extends BaseTestLoanIQ` class for the LoanIQ REST API **Create** operation only, achieving maximum test coverage using real DB-backed integration patterns.
>
> **Supported Operation**: **Create only**. For Update, Query, or Delete test generation, use the corresponding skill (`lending-update-test-api`, `lending-query-test-api`, `lending-delete-test-api`).
>
> **Two Modes of Operation**:
> - **Specification Mode** (spreadsheet provided): Parse all attributes from the **Create sheet** of the requirement spreadsheet following `lending-create-test-api` skill instructions, generate tests for every attribute, PLUS inspect the `LiqAPICreate{BusinessObject}Integration` class and all its parent classes for supplemental test cases.
> - **Code-Inspection Mode** (no spreadsheet): Inspect the `LiqAPICreate{BusinessObject}Integration` class and all its parent classes to derive test cases from field definitions, `@LiqAPIFieldMapper` annotations, validators, and business rules. Entity-name is provided by the GitHub Action `lending-api-junit-generator`. If entity-name is not provided, skip JUnit generation entirely.

---

## Pre-Flight Check — Specification Sheet Detection

**BEFORE doing anything else**, determine which mode to run:

```
IS a specification spreadsheet path provided in the prompt?
  ├─ YES → SPECIFICATION MODE
  │         Step A: Parse spreadsheet using lending-create-test-api script pipeline
  │         Step B: ALSO run Class-Hierarchy Inspection for supplemental tests
  │         Step C: Generate tests combining both sources
  └─ NO  → CODE-INSPECTION MODE
            Step A: Check if entity-name was provided by GitHub Action 'lending-api-junit-generator'
            Step B: IF entity-name NOT provided → STOP — do NOT generate any JUnit class
            Step C: IF entity-name IS provided → run Class-Hierarchy Inspection only
```

---

## Constraint Categories (in priority order)

**Primary — Test Constraints** (applies to generated Java test code only):
- Integration tests ONLY — NO Mockito, NO mocks, NO stubs, NO faked responses
- Every test exercises a real DB round-trip via `invokeApiInterface()` or `callBasicExecute()`
- **STRICTLY: NEVER modify any actual API implementation class** — only API Test classes (files ending in `IntegrationTest.java`) may be created or updated

**Secondary — Spreadsheet Processing Constraints** (Specification Mode only):
- Use the provided PowerShell scripts to extract and parse spreadsheet contents
- Scripts handle .xlsx internal XML parsing and column layout detection automatically
- Fallback order: `parse-create-attributes.ps1` → `parse-create-attributes-fallback.ps1` → `parse-via-excel-com.ps1`
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

**MANDATORY — Row/Source Comment on Every Test Method:**
- If from spreadsheet: `// Spreadsheet row: {rowNumber} — {ATTRIBUTE_FIELD_NAME}`
- If from class inspection: `// Source: {ClassName}.java — field: {fieldName}`
- This comment MUST appear on the line immediately above the `@Test` annotation

**MANDATORY — Debug Logs in Every Test Method:**
- Positive tests: `LOG.debug("Testing {description}");`
- Negative tests: `LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());`

**MANDATORY — Error Message Assertion Block for ALL False Responses:**
For **every** test method where `assertEquals("false", basicExecuteOutput.getSuccess())` is asserted, you MUST immediately follow it with:
```java
basicExecuteOutput.getAPIMessages().forEach(message -> {
    if (message instanceof LiqAPIExceptionMessage) {
        LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
        LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
        assertEquals("{specific expected error message}", ((LiqAPIExceptionMessage) message).getMessage());
    }
});
```
Where `{N}` is the `@Order` value and `{specific expected error message}` is the exact validation error.

> **Reference implementations to read before generating any test**:
> - `LiqAPICreateConsolidatedCustomerIntegrationTest` — canonical Create test patterns
> - `LiqAPIUpdateConsolidatedCustomerIntegrationTest` — canonical Update test patterns
> - Any other existing tests referenced in `lending-create-test-api` skill

---

## When to Use

Use `lending-create-api-junit-generator` when:
- Generating JUnit5 integration test classes for the LoanIQ **Create API operation only**
- You have OR do NOT have a requirement spreadsheet
- Entity-name is known (provided in prompt or by `lending-api-junit-generator` GitHub Action)
- You need real DB-backed integration tests (no mocks)

DO NOT use this skill for:
- Update test classes → use `lending-update-test-api`
- Query/Get test classes → use `lending-query-test-api`
- Delete test classes → use `lending-delete-test-api`
- Generating the API implementation class itself → use `lending-create-api`
- **Any modification to actual API implementation classes** — ONLY `LiqAPICreate{BusinessObject}IntegrationTest` classes may be written

---

## Required Inputs

| # | Input | Required? | Description |
|---|---|---|---|
| 1 | **Business Object (entity-name)** | **Mandatory** | Pascal-case name of the entity (e.g., `UpfrontFee`, `Deal`). Provided in prompt OR by `lending-api-junit-generator` GitHub Action. If absent → skip generation. |
| 2 | **Operation** | **Fixed = `create`** | This skill only supports the `create` operation. If any other operation is specified, stop and redirect to the appropriate skill. |
| 3 | **Specification Spreadsheet Path** | Optional | Full path to `.xlsx` file. If absent → Code-Inspection Mode. |

### If entity-name or operation is missing:

```
To generate the Integration test class, I need:

1. Business Object Name (entity-name) — Pascal-case (e.g., UpfrontFee, Deal, Facility).
   This may be provided by the 'lending-api-junit-generator' GitHub Action.
   If not available, JUnit generation will be skipped.

2. Operation — create, update, query, or delete.

3. Specification Spreadsheet Path — optional. If not provided, tests will be
   derived by inspecting the existing Integration class and its parent classes.
```

If entity-name is not provided and no GitHub Action supplies it → **skip JUnit generation, do not create any file**.

If an operation other than `create` is specified → **stop and inform the user** to use the appropriate skill (`lending-update-test-api`, `lending-query-test-api`, or `lending-delete-test-api`).

---

## Operation

This skill supports **Create only**:

| Operation | Integration Class | Test Class |
|---|---|---|
| `create` (**only**) | `LiqAPICreate{BusinessObject}Integration` | `LiqAPICreate{BusinessObject}IntegrationTest` |

---

## How to Run

```text
#lending-create-api-junit-generator Business Object is '{BusinessObject}'. [Specification spreadsheet path: '{SpreadsheetPath}']
```

Spreadsheet path is optional. Omit it to run in Code-Inspection Mode.

> **Note**: The operation is always `create`. If you need tests for update/query/delete, use the corresponding skill.

---

## Output Format

Test class location:
```text
LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/LiqAPICreate{BusinessObject}IntegrationTest.java
```

JSON payload location (generated if missing):
```text
LoanIQ/test-resources/json/{domain}/Create{BusinessObject}Integration.json
```

The test class:
- Extends `BaseTestLoanIQ`
- Uses `@TestMethodOrder(MethodOrderer.OrderAnnotation.class)`
- **If test class already exists**: append-only — find the last `@Order(N)` value, start new tests from `@Order(N+1)`. NEVER modify existing test methods.
- **If test class does not exist**: create it fresh from `@Order(1)`

---

## Spreadsheet Processing Rules (Specification Mode only)

> Skip entirely if no spreadsheet path is provided.

All scripts are located at: `.github/skills/lending-create-api-junit-generator/scripts/`

### Script 1: Extract the Spreadsheet
```powershell
.\scripts\extract-spreadsheet.ps1 -SpreadsheetPath "{SpreadsheetPath}"
```

### Script 2: Find the Operation Sheet
```powershell
.\scripts\find-create-sheet.ps1 -ExtractedPath "{ExtractedPath}"
```
If no matching sheet found → stop and ask user for valid spreadsheet.

### Script 3: Parse All Attributes
```powershell
.\scripts\parse-create-attributes.ps1 -ExtractedPath "{ExtractedPath}" -SheetFile "{SheetFile}"
```

### Script 3a (Fallback):
```powershell
.\scripts\parse-create-attributes-fallback.ps1 -ExtractedPath "{ExtractedPath}" -SheetFile "{SheetFile}"
```

### Script 3b (Last Resort):
```powershell
.\scripts\parse-via-excel-com.ps1 -SpreadsheetPath "{SpreadsheetPath}"
```

**Fallback Decision:**
```
parse-create-attributes.ps1 → SUCCESS: continue
                            → FAILURE: try parse-create-attributes-fallback.ps1
                                → SUCCESS: continue
                                → FAILURE: try parse-via-excel-com.ps1
                                    → SUCCESS: continue
                                    → FAILURE: ask user to provide attributes manually
```

### Attribute Data Interpretation
- `FieldName` — JSON/Java field name
- `DataType` — String, Integer, Number, Boolean, Date, Enum, List, Object
- `Required` — Y (mandatory), N (optional), CR (conditionally required)
- `Description` — business rules, defaults, constraints, validation info
- `Category` — grouping
- `DefaultValue` — default if field omitted

**CRITICAL:** For every spreadsheet row:
- Read `ATTRIBUTE_FIELD_NAME` → field name for test generation
- Read `ATTRIBUTE_DESCRIPTION` → generate description-based test cases
- Include comment: `// Spreadsheet row: {rowNumber} — {ATTRIBUTE_FIELD_NAME}`

---

## Class-Hierarchy Inspection (MANDATORY in BOTH Modes)

After spreadsheet parsing (Specification Mode) or instead of it (Code-Inspection Mode), inspect the Integration class and all its parent classes.

### Steps

1. **Locate Integration class**: `LiqAPI{Operation}{BusinessObject}Integration.java` — search in `LoanIQ/srcgen/` first, then `LoanIQ/src/`.

2. **Read the superclass**: Read the `extends` clause and open that file.

3. **Walk the full hierarchy** up to (but not including) `Object`.

4. **For each class, extract:**
   - All fields annotated with `@LiqAPIFieldMapper`
   - Setter methods and parameter types (for null-based negative tests)
   - `validate()` or `doValidate()` override methods (extract expected error messages for assertions)
   - `nonPrimitiveFieldMappings()` and `primitiveFieldMappings()`
   - `securityAccessSymbol()`

5. **For each discovered field not already covered:**
   - Positive test: set valid value → success
   - Negative test if mandatory: set null → failure with `assertEquals` on error message
   - Invalid value test if code table referenced

6. **Comment format for class-inspection tests:**
   `// Source: {ClassName}.java — field: {fieldName}`

### Reference Classes (MUST read before generating)
- `LiqAPICreateConsolidatedCustomerIntegrationTest.java`
- `LiqAPIUpdateConsolidatedCustomerIntegrationTest.java`
- All reference test classes listed in `lending-create-test-api` skill

---

## Class Name Convention

| Role | Pattern | Example (`UpfrontFee`) |
|---|---|---|
| Integration class | `LiqAPICreate{BusinessObject}Integration` | `LiqAPICreateUpfrontFeeIntegration` |
| Test class | `LiqAPICreate{BusinessObject}IntegrationTest` | `LiqAPICreateUpfrontFeeIntegrationTest` |
| Response class | `LiqAPI{BusinessObject}IntegrationAsReturnValue` | `LiqAPIUpfrontFeeIntegrationAsReturnValue` |
| Identifier class | `LiqAPI{BusinessObject}Identifier` | `LiqAPIUpfrontFeeIdentifier` |
| Java package | `com.misys.liq.api.rest.executable.{domain}` | `com.misys.liq.api.rest.executable.upfrontfee` |
| Enum prefix | `CREATE_{SCREAMING_SNAKE_CASE}_*` | `CREATE_UPFRONTFEE_TRANSACTION_*` |

- Domain = lowercased no-separator form of BusinessObject (e.g., `UpfrontFee` → `upfrontfee`)
- Operation is always **`Create`** (capitalized)

---

## Codebase Discovery (mandatory before code generation)

Run discovery script:
```powershell
.\scripts\discover-codebase.ps1 -BusinessObject "{BusinessObject}" -CodebasePath "C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ"
```

Discovers: `LiqAPICreate{BusinessObject}Integration` class, response class, `GeneralIntegrationMapping` CREATE_* enum constants, security symbol, package path.

Post-script: verify setters, imports, `@LiqAPIFieldMapper` annotations by reading the actual source files.

---

## JSON Request Payload

> **MANDATORY:** If the JSON payload file does not exist, generate it before writing any test methods.

**Template reference**: `.github/skills/lending-create-api-junit-generator/templates/json-request.md`

**Expected JSON location**:
```
LoanIQ/test-resources/json/{domain}/Create{BusinessObject}Integration.json
```

**If file does not exist**: generate from spreadsheet Create sheet attributes (Specification Mode) or from discovered `LiqAPICreate{BusinessObject}Integration` class fields (Code-Inspection Mode) using the structure in `templates/json-request.md`. Save to the correct path.

Also check: `IntegrationAPITool/artifacts/temp_generated_class/` for newly scaffolded objects.

---

## Allowed APIs (whitelist)

| Helper | Purpose |
|---|---|
| `getMainObjectFromJsonCreate(enum, Class)` | Build request DTO from JSON template |
| `LiqApiDataUtil.getObjectFromJson(enum, Class)` | Static variant |
| `invokeApiInterface(liqAPIData)` | Single-commit DB round trip |
| `LiqApiDataUtil.callBasicValidate(liqAPIData)` | Input validation |
| `LiqApiDataUtil.callBasicExecute(liqAPIData)` | Execute and return response |
| `LiqApiDataUtil.callSetParents(liqAPIData)` | Set parent linkage |
| `LiqApiDataUtil.generateIdempotencyKey()` + `setIdempotencyKey(...)` | Mandatory POST header |
| `basicExecuteOutput.getAPIMessages()` / `getSuccess()` / `getResult()` | Response assertions |
| `liqAPIData.securityAccessSymbol()` | Security symbol verification |
| `LiqAPICreate{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings()` | Mapping coverage |
| `LiqAPICreate{BusinessObject}Integration.clazz.primitiveFieldMappings()` | Mapping coverage |
| `DateUtility.getDateAsFormattedString(date, format)` | Date formatting |
| `LOG.debug(...)` | Debug logging (mandatory in every test) |
| `LOG.error(...)` | Error logging (mandatory in every negative test) |

**NEVER use:**
- `Mockito.mock(...)`, `@Mock`, `mockStatic`, `spy`, `@InjectMocks`, `PowerMock`
- Manually instantiated `LiqAPIResponse`
- Stubbed or faked response objects
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
import java.util.Properties;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPICreate{BusinessObject}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPICreate{BusinessObject}IntegrationTest.class);

    private LiqAPICreate{BusinessObject}Integration liqAPIData;
    private LiqAPIResponse basicExecuteOutput;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }
}
```

**IMPORTANT — Existing Test Class:**
- If `LiqAPICreate{BusinessObject}IntegrationTest.java` already exists → READ it first
- Find the highest `@Order(N)` value in the file
- All new `@Order` tests start from `N + 1`
- **DO NOT modify, delete, or reorder any existing test method**

---

## Test Generation Strategy

### Phase 0: Existing Class Check (MANDATORY first step)

1. Check if `LiqAPICreate{BusinessObject}IntegrationTest.java` exists in `IntegrationAPITool/artifacts/temp_generated_class/` first.
2. If not there, check `LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/`.
3. If found anywhere: read it, find last `@Order(N)`, set `nextOrder = N + 1`.
4. If not found: `nextOrder = 1`.

### Phase 1: Mandatory Field Validation Tests (negative, ordered)

For every `Required=Y` attribute:

```java
// Spreadsheet row: {rowNumber} — {fieldName}
@Test
@Order({nextOrder})
public void testCreate{BusinessObject}Without{FieldName}() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.{ENUM_CONSTANT}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.set{FieldName}(null);
    LOG.debug("Order {N} - Testing without {FieldName}");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message -> {
        if (message instanceof LiqAPIExceptionMessage) {
            LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
            LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
            assertEquals("A value is required for field {fieldName}.", ((LiqAPIExceptionMessage) message).getMessage());
        }
    });
}
```

### Phase 2: Invalid Value Tests (negative, ordered)

For attributes with validation rules (code tables, length limits, format constraints):

```java
// Spreadsheet row: {rowNumber} — {fieldName}
@Test
@Order({nextOrder})
public void testCreate{BusinessObject}WithInvalid{FieldName}() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.{ENUM_CONSTANT}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.set{FieldName}("TOOLNG");
    LOG.debug("Order {N} - Testing {FieldName} with invalid value");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message -> {
        if (message instanceof LiqAPIExceptionMessage) {
            LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
            LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
            assertEquals("Value TOOLNG of field {fieldName} should have a maxSize of {N}.", ((LiqAPIExceptionMessage) message).getMessage());
        }
    });
}
```

### Phase 3: Positive / Happy-Path Tests (unordered)

For every attribute (mandatory AND optional):

```java
// Spreadsheet row: {rowNumber} — {fieldName}
@Test
public void testCreate{BusinessObject}With{FieldName}() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.{ENUM_CONSTANT}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.set{FieldName}({validValue});
    LOG.debug("Testing Create {BusinessObject} with valid {fieldName}");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    assertNotNull(basicExecuteOutput.getResult());
}
```

### Phase 4: ATTRIBUTE_DESCRIPTION-Based Tests (MANDATORY — Specification Mode)

**CRITICAL:** For every attribute with content in `ATTRIBUTE_DESCRIPTION`, generate an additional test:

- Business rule → test validating that rule
- Constraints (min/max, format) → boundary/validation test
- Conditional behavior ("if X then Y") → conditional logic test
- Code table values → valid/invalid value tests
- Relationships → relational validation test

All description-based tests must include the full error message assertion block when `getSuccess()` == "false".

### Phase 5: Default Value Tests

```java
// Spreadsheet row: {rowNumber} — {fieldName} — Default
@Test
public void testCreate{BusinessObject}{FieldName}Default() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.{ENUM_CONSTANT}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    // Do NOT set field — let default apply
    LOG.debug("Testing {fieldName} default value behavior");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
}
```

### Phase 6: Boundary / Edge Case Tests

- Numeric: max value, min value, zero, negative
- String: exceed max length → failure
- Date: future date, past date, boundary dates

### Phase 7: Complex Object / List Tests

- Single valid entry, multiple entries, empty list, invalid entry within list, duplicate entries

### Phase 8: Identifier Variation Tests

- One positive test per supported identifier type
- One test with invalid identifier type
- One test with non-existent identifier value

### Phase 9: Class-Hierarchy-Derived Tests (BOTH Modes)

For fields discovered via class inspection not already covered by spreadsheet:

```java
// Source: {ClassName}.java — field: {fieldName}
@Test
public void testCreate{BusinessObject}{FieldName}FromClassInspection() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.{ENUM_CONSTANT}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.set{FieldName}({validValue});
    LOG.debug("Testing {fieldName} discovered from class hierarchy inspection");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    assertNotNull(basicExecuteOutput.getResult());
}
```

---

## Mandatory Idempotency Key Test

```java
// Mandatory: idempotency key missing test
@Test
@Order(1)
public void testCreate{BusinessObject}WithoutIdempotencyKey() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.{ENUM_CONSTANT}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    // Deliberately do NOT call setIdempotencyKey
    LOG.debug("Order 1 - Testing Create {BusinessObject} without idempotency key");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message -> {
        if (message instanceof LiqAPIExceptionMessage) {
            LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
            LOG.error("Order 1 - API Exception Message: " + exceptionMessage.getMessage());
            assertNotNull(exceptionMessage.getMessage());
        }
    });
}
```

---

## Mandatory Class-Mapping Coverage Tests

```java
@Test
public void testNonPrimitiveFieldMappings() {
    assertFalse(LiqAPICreate{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings().isEmpty());
}

@Test
public void testPrimitiveFieldMappings() {
    assertFalse(LiqAPICreate{BusinessObject}Integration.clazz.primitiveFieldMappings().isEmpty());
}

@Test
public void testSecurityAccessSymbol() throws JsonProcessingException {
    LiqAPICreate{BusinessObject}Integration data = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
    assertEquals("{ExpectedSecuritySymbol}", data.securityAccessSymbol());
}
```

---

## Response Assertions (Output Validation)

After every successful operation:

```java
assertEquals("true", basicExecuteOutput.getSuccess());
Object result = basicExecuteOutput.getResult();
assertNotNull(result);
LiqAPI{BusinessObject}IntegrationAsReturnValue response =
    (LiqAPI{BusinessObject}IntegrationAsReturnValue) result;
assertNotNull(response.getId());               // or getTransactionId()
assertNotNull(response.getUpdateTimeStamp());  // if present
```

Getter method determined during Codebase Discovery Step 2.

---

## Compilation Safety Rules

1. **Never reference a class that does not exist** — verify via codebase discovery
2. **Never call a method that does not exist** — verify getter/setter names from actual source
3. **Never modify any API implementation class** — only test class files
4. **Use correct generics** when casting `getResult()`
5. **Import all used classes** — complete import statements
6. **Match enum constant names exactly** — copy from `GeneralIntegrationMapping.java`
7. **Correct assertion methods** — from `org.junit.jupiter.api.Assertions`
8. **All test methods declare** `throws JsonProcessingException`
9. **Only reference JSON templates that exist** (enum constants verified in discovery)
10. **Match actual setter signatures** — `setX(String)`, `setX(Boolean)`, etc.
11. **Always import `LogManager`** from `org.apache.logging.log4j.LogManager`
12. **`@Order` values are sequential and non-duplicated** — append from `lastOrder + 1`

---

## Coverage Checklist

Before finalizing:

- [ ] Every Required=Y attribute has null/missing negative test
- [ ] Every Required=Y attribute has valid positive test
- [ ] Every optional attribute has at least one positive test
- [ ] Every attribute with validation rules has invalid-value negative test
- [ ] Every attribute with defaults has default-verification test
- [ ] Every identifier group has per-type tests + invalid tests
- [ ] Idempotency key test present (Create/Update)
- [ ] Class-mapping coverage tests (3) present
- [ ] Security access symbol test present
- [ ] All enum constants have at least one associated test
- [ ] Response assertions verify all output fields
- [ ] Every test method has source comment (row number or class field)
- [ ] Every test method has LOG.debug or LOG.error statements
- [ ] All false-response tests have full error message assertion block
- [ ] JSON payload file exists (generated if missing)
- [ ] No actual API implementation classes were modified

---

## Don'ts

- No `Mockito.mock(...)`, `@Mock`, `mockStatic`, `spy`, or `@InjectMocks`
- No manually instantiated `LiqAPIResponse`
- No tests bypassing `BaseTestLoanIQ` initialization
- No getter/setter-only tests — must go through `invokeApiInterface` round-trip
- No hardcoded RIDs or identifiers
- No test methods without assertions
- No duplicate test methods
- No tests depending on other tests (each is self-contained)
- **No modifications to any actual API implementation class**
- No test methods without source comment
- No test methods without debug log statements

---

## Execution Workflow Summary

> **Scripts location**: `.github/skills/lending-create-api-junit-generator/scripts/`

```
0. PRE-FLIGHT: Detect mode
   ├─ SpreadsheetPath provided? → SPECIFICATION MODE
   └─ No SpreadsheetPath?
       ├─ entity-name from 'lending-api-junit-generator' GitHub Action? → CODE-INSPECTION MODE
       └─ No entity-name? → STOP — skip JUnit generation
   NOTE: If any operation other than 'create' is specified → STOP and redirect to the correct skill

[SPECIFICATION MODE: Steps 1-4]
1. extract-spreadsheet.ps1 → produces extracted XML folder
2. find-create-sheet.ps1   → finds the Create sheet XML
3. parse-create-attributes.ps1 (+ fallback chain) → structured attribute list from Create sheet
   └─ IF ALL FAIL → ask user for manual attributes

[BOTH MODES: Steps 4+]
4. CLASS-HIERARCHY INSPECTION
   ├─ Read LiqAPICreate{BusinessObject}Integration.java + all parent classes
   ├─ Extract: @LiqAPIFieldMapper fields, setters, validate() methods, mappings, security symbol
   └─ Read reference classes:
       ├─ LiqAPICreateConsolidatedCustomerIntegrationTest.java
       └─ LiqAPIUpdateConsolidatedCustomerIntegrationTest.java

5. discover-codebase.ps1 → integration class, response class, enum constants, security symbol

6. JSON PAYLOAD CHECK
   ├─ Read LoanIQ/test-resources/json/{domain}/Create{BusinessObject}Integration.json
   ├─ Read .github/skills/lending-create-api-junit-generator/templates/json-request.md
   ├─ Check IntegrationAPITool/artifacts/temp_generated_class/
   └─ IF JSON NOT FOUND → GENERATE from Create sheet attributes/class fields → SAVE to correct path

7. EXISTING TEST CLASS CHECK
   ├─ Check IntegrationAPITool/artifacts/temp_generated_class/ for LiqAPICreate{BusinessObject}IntegrationTest.java
   ├─ Check LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/ for LiqAPICreate{BusinessObject}IntegrationTest.java
   ├─ IF FOUND → read file, find last @Order(N), set nextOrder = N + 1
   │             STRICT: do NOT modify any existing test method
   └─ IF NOT FOUND → nextOrder = 1 (new class)

8. GENERATE TEST METHODS
   ├─ Phase 1: Mandatory field negative tests (ordered from nextOrder)
   ├─ Phase 2: Invalid value negative tests (ordered)
   ├─ Phase 3: Positive happy-path tests (unordered)
   ├─ Phase 4: ATTRIBUTE_DESCRIPTION-based tests (Specification Mode)
   ├─ Phase 5: Default value tests
   ├─ Phase 6: Boundary/edge case tests
   ├─ Phase 7: Complex object/list tests
   ├─ Phase 8: Identifier variation tests
   ├─ Phase 9: Class-hierarchy-derived tests
   ├─ Mandatory: Idempotency key test
   ├─ Mandatory: Class-mapping coverage tests (3)
   └─ Mandatory: Response assertions

9. PLACE FILE at:
   C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ\test\com\misys\liq\api\rest\executable\{domain}\
   LiqAPICreate{BusinessObject}IntegrationTest.java

10. RUN tests → collect PASS/FAIL per method

11. FIX failing tests iteratively:
    a. Analyze failure (compilation, assertion, runtime)
    b. Fix ONLY the failing test — never touch passing tests
    c. Re-run all
    d. Repeat until 100% pass

12. GENERATE gap report: lending-create-api-junit-generator.md (same folder as test class)
    Columns: S.No. | Attributes | Covered (True/False) | Reason for not covered
    - One row per attribute (from spreadsheet or class inspection)
    - Source column indicates whether from spreadsheet row or class field
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
| `extract-spreadsheet.ps1` | `.github/skills/lending-create-api-junit-generator/scripts/` | Extract .xlsx to XML |
| `find-create-sheet.ps1` | `.github/skills/lending-create-api-junit-generator/scripts/` | Find operation worksheet |
| `parse-create-attributes.ps1` | `.github/skills/lending-create-api-junit-generator/scripts/` | Parse attribute rows (primary) |
| `parse-create-attributes-fallback.ps1` | `.github/skills/lending-create-api-junit-generator/scripts/` | Dynamic header detection fallback |
| `parse-via-excel-com.ps1` | `.github/skills/lending-create-api-junit-generator/scripts/` | Excel COM fallback |
| `discover-codebase.ps1` | `.github/skills/lending-create-api-junit-generator/scripts/` | Find classes, enums, symbols |
| JSON template | `.github/skills/lending-create-api-junit-generator/templates/json-request.md` | Payload structure |
| JSON payloads | `LoanIQ/test-resources/json/{domain}/Create{BusinessObject}Integration.json` | Test data |
| Temp artifacts | `IntegrationAPITool/artifacts/temp_generated_class/` | Scaffolded objects |
| Reference test (Create) | `LiqAPICreateConsolidatedCustomerIntegrationTest.java` | Canonical pattern |
| Reference test (Update) | `LiqAPIUpdateConsolidatedCustomerIntegrationTest.java` | Pattern reference for error blocks |
| Final test location | `LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/` | Output path |
| Gap report | `lending-create-api-junit-generator.md` (same folder as test class) | Coverage report |

---

## Post Agent Run Modification

Use this prompt to **append new test cases** to an existing test class without modifying any existing code:

```
#lending-create-api-junit-generator Business Object is '<entity-name>'.
[Specification spreadsheet at: '<path>']
Strictly do not change any existing code in LiqAPICreate<entity-name>IntegrationTest.
Add new test cases starting from the last junit method in the existing class.
For all generated test methods, add a comment with the spreadsheet row number (if from spreadsheet)
or the source class field name (if from class inspection).
Add negative test cases wherever applicable.
Also inspect LiqAPICreate<entity-name>Integration and all its parent classes for additional test cases.
```

### Rules for Post-Run Modification

1. **Preserve existing code** — do NOT modify, delete, or reorder existing test methods
2. **Append-only** — start from `lastOrder + 1`
3. **Spreadsheet sheet** — use only the matching operation sheet
4. **Row/source comment MANDATORY** on every new test method
5. **Negative tests MANDATORY** for applicable attributes
6. **Full error message assertion block MANDATORY** for all false-response tests
7. **Gap report** — generate `lending-create-api-junit-generator.md` in the test package folder