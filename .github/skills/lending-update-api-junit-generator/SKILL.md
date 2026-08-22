---
name: lending-update-api-junit-generator
description: 'JUnit5 integration test generator specifically for LoanIQ Update API operations. Works with OR without a requirement specification spreadsheet. When a spreadsheet is provided, generates tests for all attributes from the Update sheet (100% coverage) AND inspects the LiqAPIUpdate<entity>Integration class hierarchy. When no spreadsheet is provided, inspects the existing LiqAPIUpdate<entity>Integration class and all its parent classes to generate comprehensive tests. Entity-name is supplied by the GitHub Action named lending-api-junit-generator. NEVER modifies actual API implementation classes — only Update IntegrationTest classes are written.'
---

# LoanIQ Update API JUnit Generator

> **Purpose**: Generate a complete `LiqAPIUpdate{BusinessObject}IntegrationTest extends BaseTestLoanIQ` class for the LoanIQ REST API **Update** operation only, achieving maximum test coverage using real DB-backed integration patterns.
>
> **Supported Operation**: **Update only**. For Create, Query, or Delete test generation use the corresponding skill (`lending-create-api-junit-generator`, `lending-query-api-junit-generator`, `lending-delete-api-junit-generator`).
>
> **Two Modes of Operation**:
> - **Specification Mode** (spreadsheet provided): Parse all attributes from the **Update sheet** following `lending-update-test-api` skill instructions, generate tests for every attribute, PLUS inspect the `LiqAPIUpdate{BusinessObject}Integration` class and all its parent classes for supplemental test cases.
> - **Code-Inspection Mode** (no spreadsheet): Inspect the `LiqAPIUpdate{BusinessObject}Integration` class and all its parent classes to derive test cases from field definitions, `@LiqAPIFieldMapper` annotations, validators, and business rules. Entity-name is provided by the GitHub Action `lending-api-junit-generator`. If entity-name is not provided, skip JUnit generation entirely.

---

## Pre-Flight Check — Specification Sheet Detection

**BEFORE doing anything else**, determine which mode to run:

```
IS a specification spreadsheet path provided in the prompt?
  ├─ YES → SPECIFICATION MODE
  │         Step A: Parse Update sheet using lending-update-test-api script pipeline
  │         Step B: ALSO run Class-Hierarchy Inspection for supplemental tests
  │         Step C: Generate tests combining both sources
  └─ NO  → CODE-INSPECTION MODE
            Step A: Check if entity-name was provided by GitHub Action 'lending-api-junit-generator'
            Step B: IF entity-name NOT provided → STOP — do NOT generate any JUnit class
            Step C: IF entity-name IS provided → run Class-Hierarchy Inspection only

NOTE: If any operation other than 'update' is specified → STOP and redirect to the correct skill.
```

---

## Class-Hierarchy Inspection (MANDATORY in BOTH Modes)

After spreadsheet parsing (Specification Mode) or instead of it (Code-Inspection Mode), inspect the Update Integration class and all its parent classes.

### Steps

1. **Locate Update Integration class**: `LiqAPIUpdate{BusinessObject}Integration.java` — search `LoanIQ/srcgen/` first, then `LoanIQ/src/`.
2. **Read the superclass** from the `extends` clause, then walk the full hierarchy up to (but not including) `Object`.
3. **For each class, extract:**
   - All fields annotated with `@LiqAPIFieldMapper`
   - Setter methods and parameter types
   - `validate()` or `doValidate()` override methods (extract expected error messages)
   - `nonPrimitiveFieldMappings()`, `primitiveFieldMappings()`, `nonPrimitiveFieldCollectionMappings()`
   - `securityAccessSymbol()`, `isRest()`, `basicNew()`, `getJavaClass()`, `getStSuperclass()`
4. **For each discovered field not already covered by spreadsheet**: generate positive test (3-step bootstrap with valid value) + negative test if mandatory.
5. **Comment format for class-inspection tests**: `// Source: {ClassName}.java — field: {fieldName}`
6. **Also locate**: `LiqAPICreate{BusinessObject}Integration.java` and `LiqAPIQuery{BusinessObject}Integration.java` — needed for 3-step bootstrap.

### Reference Classes (MUST read before generating)
- `LiqAPICreateConsolidatedCustomerIntegrationTest.java`
- `LiqAPIUpdateConsolidatedCustomerIntegrationTest.java`
- All reference test classes listed in `lending-update-test-api` skill

---

## Sample Prompt

> `/lending-update-api-junit-generator Generate the Update integration test class for the UpfrontFee business object [using the spreadsheet at C:\Auto\API\Upfront Fee v2.1.xlsx]`

---

## Required Inputs

| # | Input | Required? | Description |
|---|---|---|---|
| 1 | **Business Object (entity-name)** | **Mandatory** | Pascal-case name (e.g., `Deal`, `Facility`, `UpfrontFee`). Provided in prompt OR by `lending-api-junit-generator` GitHub Action. If absent → skip generation. |
| 2 | **Operation** | **Fixed = `update`** | This skill only supports `update`. If any other operation is specified, stop and redirect to the appropriate skill. |
| 3 | **Specification Spreadsheet Path** | Optional | Full path to `.xlsx` file. If absent → Code-Inspection Mode. |

**⚠️ If entity-name is missing:**

```
To generate the Update Integration test class, I need:

1. Business Object Name (entity-name) — Pascal-case (e.g., Deal, Facility, UpfrontFee).
   This may be provided by the 'lending-api-junit-generator' GitHub Action.
   If not available, JUnit generation will be skipped.

2. Specification Spreadsheet Path — optional. If not provided, tests will be
   derived by inspecting the existing LiqAPIUpdate<entity>Integration class and its parent classes.
```

If entity-name is not provided and no GitHub Action supplies it → **skip JUnit generation, do not create any file**.

If an operation other than `update` is specified → **stop and inform the user** to use the appropriate skill.

---

## When to Use This Skill

Use `lending-update-api-junit-generator` when:
- Generating JUnit5 integration test classes for the LoanIQ **Update API operation only**
- You have OR do NOT have a requirement spreadsheet
- Entity-name is known (provided in prompt or by `lending-api-junit-generator` GitHub Action)
- You need real DB-backed integration tests (no mocks)

DO NOT use this skill for:
- Create test classes → use `lending-create-api-junit-generator`
- Query/Get test classes → use `lending-query-api-junit-generator`
- Delete test classes → use `lending-delete-api-junit-generator`
- Generating the Update API implementation class itself → use `lending-update-api`
- **Any modification to actual API implementation classes** — ONLY `LiqAPIUpdate{BusinessObject}IntegrationTest` classes may be written

---

## How to Run

```text
#lending-update-api-junit-generator Business Object is '{BusinessObject}'. [Specification spreadsheet path: '{SpreadsheetPath}']
```

Spreadsheet path is optional. Omit it to run in Code-Inspection Mode.

> **Note**: The operation is always `update`. If you need tests for create/query/delete, use the corresponding skill.

---

## Output Format

Test class location:
```text
LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/LiqAPIUpdate{BusinessObject}IntegrationTest.java
```

JSON payload location (generated if missing):
```text
LoanIQ/test-resources/json/{domain}/Update{BusinessObject}Integration.json
```

The test class:
- Extends `BaseTestLoanIQ`
- Uses `@TestMethodOrder(MethodOrderer.OrderAnnotation.class)`
- Contains integration tests with `@Order` annotations
- **If test class already exists**: append-only — find last `@Order(N)`, start new tests from `@Order(N+1)`. NEVER modify existing test methods.
- **If test class does not exist**: create it fresh from `@Order(1)`
- Generates a coverage report at `lending-update-api-junit-generator.md`

**MANDATORY — Row/Source Comment on Every Test Method:**
- If from spreadsheet: `// Spreadsheet row: {rowNumber} — {ATTRIBUTE_FIELD_NAME}`
- If from class inspection: `// Source: {ClassName}.java — field: {fieldName}`
- This comment MUST appear on the line immediately above the `@Test` annotation

**MANDATORY — Debug Logs in Every Test Method:**
- Positive tests: `LOG.debug("Testing {description}");`
- Negative tests: `LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());`

**MANDATORY — Error Message Assertion Block for ALL False Responses:**
For every test where `assertEquals("false", basicExecuteOutput.getSuccess())`, immediately follow with:
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
> - `LiqAPIUpdateConsolidatedCustomerIntegrationTest` — canonical Update test patterns
> - All reference test classes listed in `lending-update-test-api` skill

---

## Workflow

### Step 0: Mode Detection (MANDATORY first)

```
HAS SpreadsheetPath?
  ├─ YES → SPECIFICATION MODE → Steps 1-2, then 3+
  └─ NO  → CODE-INSPECTION MODE → Skip to Step 3 (class inspection)
            └─ No entity-name? → STOP — do NOT generate any file
```

### Step 1: Parse Requirement Spreadsheet (Specification Mode only)

All scripts are located at: `.github/skills/lending-update-api-junit-generator/scripts/`

Invoke the spreadsheet parsing script to extract attribute details:

```powershell
# Primary method — use run-excel-reader.ps1
.github/agents/scripts/run-excel-reader.ps1 "<SpreadsheetPath>"
```

**Output location:** `IntegrationAPITool/artifacts/temp_generated_class/`

If the script succeeds, the generated class file `LiqAPIUpdate{BusinessObject}Integration.java` will be available in the temp folder along with the Update request payload JSON template.

#### Fallback: If Spreadsheet Parsing Fails

If the primary script fails because the spreadsheet is not in the required format, **DO NOT STOP**. Use the alternative extraction scripts under the `scripts/` subfolder of this skill:

```powershell
# Fallback 1: Extract attributes using column-header detection
.github/skills/lending-update-api-junit-generator/scripts/extract-attributes-flexible.ps1 "<SpreadsheetPath>" "Update"

# Fallback 2: Extract attributes from a non-standard layout
.github/skills/lending-update-api-junit-generator/scripts/extract-attributes-alt-format.ps1 "<SpreadsheetPath>"

# Fallback 3: Manual CSV-based extraction
.github/skills/lending-update-api-junit-generator/scripts/extract-from-csv.ps1 "<SpreadsheetPath>"
```

These fallback scripts produce a normalized `attributes.json` file containing:
```json
{
  "businessObject": "EntityName",
  "attributes": [
    {
      "name": "fieldName",
      "type": "String|BigDecimal|Date|Boolean|List",
      "required": true|false,
      "updatable": true|false,
      "codeTable": "TableName or null",
      "description": "Field description",
      "isPrimitive": true|false,
      "isCollection": false|true
    }
  ]
}
```

Continue test generation using this normalized output regardless of which extraction method succeeded.

**CRITICAL REQUIREMENT — Spreadsheet Column Reading:**

For every row in the Update sheet of the requirement spreadsheet:
- Read **ATTRIBUTE_FIELD_NAME** column → Use as the field name for test generation
- Read **ATTRIBUTE_DESCRIPTION** column → Use to generate description-based test cases

**Conditional Processing:** These columns are ONLY processed if:
- The "Update" sheet exists in the requirement spreadsheet
- The operation type "Update" is valid for this business object
- If the Update sheet does not exist, skip Update test generation or prompt user

**Test Generation from ATTRIBUTE_DESCRIPTION:**

**CONDITIONAL LOGIC:**

1. **If ATTRIBUTE_DESCRIPTION is BLANK or EMPTY:**
   - Generate ONLY the basic JUnit test method for the attribute
   - Do NOT generate description-based test
   - Move forward to next attribute

2. **If ATTRIBUTE_DESCRIPTION has CONTENT:**
   - Generate the basic JUnit test method for the attribute
   - ADDITIONALLY generate description-based JUnit test method(s) validating:
     - Business rules mentioned in description
     - Constraints (min/max, format, pattern)
     - Conditional behavior ("if X then Y")
     - Code table values
     - Relationships to other fields
     - Special scenarios
     - Updatability restrictions

### Step 2: Locate or Create Test File

Follow this decision tree to determine where to generate the test class:

#### Step 2A: Check Temp Folder First

Check if `LiqAPIUpdate{BusinessObject}IntegrationTest.java` exists in:
```
IntegrationAPITool/artifacts/temp_generated_class/
```

- **EXISTS in temp folder** → Read it, find last `@Order(N)`, set `nextOrder = N + 1`. **DO NOT modify existing test methods.** Move to final location after generating new tests.
- **NOT in temp folder** → Check repo directly (Step 2C).

#### Step 2B: Update Test File in Temp Folder, Then Move

1. Read the existing file, find the highest `@Order(N)` value — all new `@Order` tests start from `N + 1`.
2. Append new JUnit test methods following the patterns in `references/example.md` and `references/Update-test-class-structure.md`
3. Move the file to:
```
C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ\test\com\misys\liq\api\rest\executable\{domain}\LiqAPIUpdate{BusinessObject}IntegrationTest.java
```

#### Step 2C: Check Repo Test Folder Directly

Check:
```
C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ\test\com\misys\liq\api\rest\executable\{domain}\LiqAPIUpdate{BusinessObject}IntegrationTest.java
```

- **EXISTS in repo** → Read it, find last `@Order(N)`, append new tests from `N + 1`. NEVER overwrite existing test methods.
- **NOT in repo** → Create brand new test class from `@Order(1)`.

### Step 3: Identify Entity Type and Bootstrap Pattern

Determine which bootstrap pattern applies based on the business object:

| Entity Type | Pattern | Example Entities |
|---|---|---|
| **Standalone with Create** | CREATE → QUERY → UPDATE (3-step) | Deal, Facility, UpfrontFee, LoanDrawdown, LoanRepricing, LoanInterestPayment, LoanPrincipalPayment, Primary, ProductGuarantee |
| **Owner-based (no Create)** | QUERY → UPDATE (2-step) | MISCode, AdditionalFields |

### Step 4: Load Update Request Payload Template

> **MANDATORY:** If the JSON payload file does not exist, generate it before writing any test methods.

**Template reference**: `.github/skills/lending-update-api-junit-generator/templates/generic-update-request.json`

**Expected JSON location**:
```
LoanIQ/test-resources/json/{domain}/Update{BusinessObject}Integration.json
```

Also check: `IntegrationAPITool/artifacts/temp_generated_class/`

If not found → generate from Update sheet attributes (Specification Mode) or from discovered `LiqAPIUpdate{BusinessObject}Integration` class fields (Code-Inspection Mode). Save to the correct path.

Each JUnit test method uses this template as the base payload via `getMainObjectFromJsonUpdate()`, then mutates specific fields for each test scenario.

### Step 5: Generate Test Class

Generate the test class following the patterns in:
- `references/example.md` — Complete code patterns for all test scenarios
- `references/Update-test-class-structure.md` — Generic class structure template

**Every generated test method MUST include:**
1. A source comment (`// Spreadsheet row:` or `// Source: ClassName.java`) immediately above `@Test`
2. `LOG.debug(...)` for positive paths
3. `LOG.error(...)` inside every `LiqAPIExceptionMessage` block
4. Full error message assertion block for every false-response test

### Step 6: Validate Coverage

Ensure the generated test class covers:
- ✅ ALL mandatory attributes (positive + negative tests)
- ✅ ALL optional attributes (positive tests + boundary cases)
- ✅ **CRITICAL:** ALL attributes with ATTRIBUTE_DESCRIPTION have description-based tests validating mentioned rules/constraints/scenarios
- ✅ ALL primitive field mappings (String, BigDecimal, Date, Boolean)
- ✅ ALL non-primitive single object mappings
- ✅ ALL non-primitive collection mappings (List<> fields)
- ✅ Identifier validation tests
- ✅ If-Match timestamp validation tests
- ✅ Class-mapping coverage tests (nonPrimitiveFieldMappings, primitiveFieldMappings, securityAccessSymbol, isRest, basicNew, getJavaClass, getStSuperclass)
- ✅ Getter/Setter tests for all fields
- ✅ Invalid code table value tests
- ✅ Non-updatable field tests (verify they cannot be modified)
- ✅ Collection field tests (add, modify, remove, duplicates)
- ✅ ~100% attribute coverage from the spreadsheet

### Step 7: Run Test Cases

After all test cases are generated, **run the test class** to verify compilation and execution:

```powershell
# Run the generated test class
cd C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ
ant unittest -Dtest.class=com.misys.liq.api.rest.executable.{domain}.LiqAPIUpdate{BusinessObject}IntegrationTest
```

Or use the VS Code JUnit test runner to execute the test class.

### Step 8: Fix Failing Test Cases

If any test cases fail:

1. **Read the error output** — Identify compilation errors or runtime assertion failures.
2. **Fix compilation issues** — Missing imports, incorrect method signatures, wrong class names, incorrect casting.
3. **Fix assertion failures** — Wrong expected values, incorrect field names, wrong enum constants.
4. **Fix logic errors** — Incorrect bootstrap pattern, missing timestamp binding, wrong identifier wiring.

**Common fixes:**
- Missing import → Add the correct import statement
- Method not found → Verify the method name against the actual Integration class
- ClassCastException → Fix the response casting (single object vs List)
- Enum constant not found → Verify `GeneralIntegrationMapping` has the referenced constant
- NullPointerException → Add null-checks or fix bootstrap wiring order

### Step 9: Re-Run and Iterate Until All Tests Pass

After fixing test cases:

1. **Re-run the test class** again.
2. **If tests still fail** → Go back to Step 8 and fix.
3. **Repeat this cycle** (fix → run → verify) until ALL test cases pass.
4. **Do NOT stop** until zero failures are reported.

> **STRICT RULE**: Keep iterating between fix and run until the test run shows 0 failures. There is no maximum iteration count — fix every failing test.

### Step 10: Generate Coverage Report

Once ALL test cases pass, generate a coverage report file:

**Report file location:** Same directory as the test class:
```
C:\Users\asrivas3\git\master\FLIQ-liqjava\LoanIQ\test\com\misys\liq\api\rest\executable\{domain}\lending-update-api-junit-generator.md
```

**Report format:**

```markdown
# Update Test API Coverage Report — {BusinessObject}

## Test Execution Summary

| Metric | Value |
|---|---|
| Business Object | {BusinessObject} |
| Test Class | LiqAPIUpdate{BusinessObject}IntegrationTest |
| Total Tests | {count} |
| Passed | {count} |
| Failed | 0 |
| Spreadsheet | {SpreadsheetPath} |
| Generated Date | {date} |

## Test Case Results

| # | Test Method | Status | Category |
|---|---|---|---|
| 1 | testUpdateWithoutIdentifierValue | ✅ PASS | Identifier Validation |
| 2 | testUpdateWithNonExistentEntity | ✅ PASS | Identifier Validation |
| ... | ... | ... | ... |

## Attribute Coverage Matrix

| # | Attribute (from Spreadsheet) | Type | Required | Updatable | Test Coverage | Test Method(s) |
|---|---|---|---|---|---|---|
| 1 | {attributeName} | {type} | Y/N | Y/N | ✅ Covered / ❌ Not Covered | testMethod1, testMethod2 |
| ... | ... | ... | ... | ... | ... | ... |

## Coverage Summary

| Category | Total | Covered | Coverage % |
|---|---|---|---|
| Mandatory Attributes | {n} | {n} | {%} |
| Optional Attributes | {n} | {n} | {%} |
| Primitive Fields | {n} | {n} | {%} |
| Non-Primitive Fields | {n} | {n} | {%} |
| Collection Fields | {n} | {n} | {%} |
| Class Mapping Tests | 9 | {n} | {%} |
| **Overall** | **{n}** | **{n}** | **{%}** |

## Uncovered Attributes (if any)

| # | Attribute | Reason |
|---|---|---|
| — | — | All attributes covered |
```

The report MUST:
- List every test method with its pass/fail status
- Map every attribute from the spreadsheet to its corresponding test method(s)
- Clearly indicate which attributes are covered and which are not
- Show overall coverage percentage
- Be generated ONLY after all tests pass (Step 9 complete)

---

## Class Name Convention

Given a business object name `{BusinessObject}`:

| Role | Naming Pattern | Example (`UpfrontFee`) |
|---|---|---|
| Integration (request) class | `LiqAPIUpdate{BusinessObject}Integration` | `LiqAPIUpdateUpfrontFeeIntegration` |
| Test class | `LiqAPIUpdate{BusinessObject}IntegrationTest` | `LiqAPIUpdateUpfrontFeeIntegrationTest` |
| Identifier class | `LiqAPI{BusinessObject}Identifier` | `LiqAPIUpfrontFeeIdentifier` |
| Response (return value) class | `LiqAPI{BusinessObject}IntegrationAsReturnValue` | `LiqAPIUpfrontFeeIntegrationAsReturnValue` |
| Create class (bootstrap seed) | `LiqAPICreate{BusinessObject}Integration` | `LiqAPICreateUpfrontFeeIntegration` |
| Query class (bootstrap fetch) | `LiqAPIQuery{BusinessObject}Integration` | `LiqAPIQueryUpfrontFeeIntegration` |
| Java package | `com.misys.liq.api.rest.executable.{domain}` | `com.misys.liq.api.rest.executable.upfrontfee` |
| `GeneralIntegrationMapping` update prefix | `UPDATE_{BUSINESS_OBJECT_UPPER}_*` | `UPDATE_UPFRONTFEE_TRANSACTION_INTEGRATION` |

**Rules:**
- Use Pascal-case for `{BusinessObject}` exactly as provided in the prompt.
- The domain (package segment) is the lowercased, no-separator form of the business object name.
- For `GeneralIntegrationMapping` enum constants, convert to `SCREAMING_SNAKE_CASE`.
- The `@TestMethodOrder`, `@BeforeEach`, and `extends BaseTestLoanIQ` annotations are always present.

---

## Allowed APIs (whitelist)

Only these helpers may appear in generated tests:

| Helper | Purpose |
|---|---|
| `getMainObjectFromJsonCreate(enum, Class)` | Bootstrap entity to update |
| `getMainObjectFromJsonQuery(enum, Class)` | Re-fetch to read current `updateTimeStamp` for If-Match |
| `getMainObjectFromJsonUpdate(enum, Class)` | Build the update DTO |
| `LiqApiDataUtil.getObjectFromJson(enum, Class)` | Load any integration DTO from JSON |
| `invokeApiInterface(liqAPIData)` | Single-commit DB round trip |
| `LiqApiDataUtil.callBasicValidate(liqAPIData)` / `basicValidate()` | Trigger input validation |
| `LiqApiDataUtil.callBasicExecute(liqAPIData)` / `basicExecute()` | Execute and return response |
| `LiqApiDataUtil.generateIdempotencyKey()` + `setIdempotencyKey(...)` | POST seed call |
| `LiqApiDataUtil.getUpdatedTimestampFromQuery(list, getter)` | Extract updateTimeStamp from query result |
| `setMatchUpdatedTimestamp(date)` | If-Match concurrency header |
| `setIdentifierValue(...)` on identifier | Target the just-created entity |
| `getAPIMessages()` / `getSuccess()` / `getResult()` | Response assertions |
| `LiqAPIUpdate{Entity}Integration.clazz.nonPrimitiveFieldMappings()` / `primitiveFieldMappings()` / `nonPrimitiveFieldCollectionMappings()` | Mapping coverage |
| `securityAccessSymbol()` | Verify security symbol |
| `DateUtility.getDateAsFormattedString(date, format)` | Date formatting |
| `setParents()` | Required for parent linkage (LoanDrawdown etc.) |

**NEVER** use Mockito, PowerMock, byte-buddy spies, or stubbed `LiqAPIResponse` instances.

---

## Attribute Coverage Rules

### CRITICAL REQUIREMENT: ATTRIBUTE_DESCRIPTION-Based Test Generation

**MANDATORY:** For every "ATTRIBUTE_FIELD_NAME" in the spreadsheet, you MUST generate an additional test case based on the "ATTRIBUTE_DESCRIPTION" column content. If the description mentions:
- Business rules → Generate a test validating that rule
- Constraints (min/max, format, pattern) → Generate a boundary/validation test
- Conditional behavior ("if X then Y") → Generate a conditional logic test
- Code table values → Generate valid/invalid value tests
- Relationships to other fields → Generate a relational validation test
- Special scenarios → Generate a scenario-specific test
- Updatability restrictions → Generate a non-updatable field test

### Mandatory Attributes (Required=Y)

For every mandatory attribute in the spreadsheet:
1. **Positive test** — set a valid value, assert success
2. **Null test** — set `null`, assert failure with appropriate error message
3. **Invalid value test** — set an invalid value (for code table fields), assert failure
4. **Description-based test** — if ATTRIBUTE_DESCRIPTION specifies additional rules, generate corresponding validation test

> **MANDATORY — Error Message Assertion Pattern:** For every negative test (steps 2 and 3 above), after `assertEquals("false", basicExecuteOutput.getSuccess())`, always include:
> ```java
> basicExecuteOutput.getAPIMessages().forEach(message -> {
>     if (message instanceof LiqAPIExceptionMessage) {
>         LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
>         LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
>         assertEquals("{specific expected error message}", ((LiqAPIExceptionMessage) message).getMessage());
>     }
> });
> ```
> Where `{N}` is the `@Order` value and `{specific expected error message}` is the exact error the API returns (e.g., `"A value is required for field shortName."`, `"Value TOOLONG of field branch is not a code in table Branch."`). See `LiqAPICreateConsolidatedCustomerIntegrationTest` for reference.

### Optional Attributes (Required=N or CR)

For every optional attribute in the spreadsheet:
1. **Positive test** — set a valid value, assert success
2. **Boundary test** — test edge cases (empty string, max length, etc.)
3. **Description-based test** — if ATTRIBUTE_DESCRIPTION specifies constraints or scenarios, generate corresponding test

### Primitive Field Mapping

For fields mapped as primitive types (`String`, `BigDecimal`, `Date`, `Boolean`, `LiqDate`):
- Use `primitiveFieldMappings()` method on the inner Class
- Each field gets a `LiqAPIViewPrimitiveFieldMapping` entry with correct `logicalFieldName`

| Java Type | Logical Field Name |
|-----------|-------------------|
| BigDecimal (monetary) | `"amount"` |
| BigDecimal (rate) | `"fxRate"` |
| Date / LiqDate | `"date"` |
| String (ID) | `"id"` |
| String (code) | field name itself (e.g., `"branchCode"`, `"currencyCode"`) |
| String (text/comment) | `"description"` |

### Non-Primitive Single Object Mapping

For complex object fields (not collections):
- Use `nonPrimitiveFieldMappings()` method on the inner Class
- Each field gets a `LiqAPINonPrimitiveFieldMapping` entry with `setFieldName()` and `setFieldApiClass()`

### Non-Primitive Collection Mapping

For `List<>` fields annotated with `@LiqAPIFieldMapper`:
- Use `nonPrimitiveFieldCollectionMappings()` method on the inner Class
- Each field gets a `LiqAPINonPrimitiveFieldMapping` entry with `setFieldName()` matching the instance variable and `setFieldApiClass()` matching the element type's `.clazz`
- Tests MUST cover: add item, modify item, remove item, duplicate detection

---

## Compilation Safety Rules

To avoid compilation errors in generated test classes:

1. **Import all referenced classes** — Generate full import statements for every class used
2. **Use correct generics** — `List<LiqAPI{Entity}IntegrationAsReturnValue>` not raw `List`
3. **Handle checked exceptions** — All test methods declare `throws JsonProcessingException`
4. **Use correct assertion imports** — `import static org.junit.jupiter.api.Assertions.*`
5. **Match method signatures** — Verify getter/setter names match the actual Integration class
6. **Use correct enum constants** — Verify `GeneralIntegrationMapping` constants exist before referencing
7. **Cast response correctly** — Use proper casting for `getResult()` based on return type (single object vs List)
8. **Logger type** — Use either `LoggerFactory.getLogger()` (SLF4J) or `LogManager.getLogger()` (Log4j2) consistently

---

## Scripts

This skill uses scripts located in the `scripts/` subfolder to assist in test generation:

| Script | Purpose | When to Use |
|---|---|---|
| `extract-attributes-flexible.ps1` | Extract attributes with flexible column-header detection | When primary parser fails on non-standard format |
| `extract-attributes-alt-format.ps1` | Extract attributes from alternative spreadsheet layout | When spreadsheet uses different sheet naming or column layout |
| `extract-from-csv.ps1` | Extract attributes from CSV export of spreadsheet | Last resort when .xlsx parsing fails entirely |
| `generate-test-skeleton.ps1` | Generate test class skeleton from normalized attributes | After attributes are extracted successfully |
| `validate-coverage.ps1` | Validate that all spreadsheet attributes have test coverage | Final verification step |

### Script Invocation Order

1. Try primary parser: `.github/agents/scripts/run-excel-reader.ps1`
2. If fails → Try: `.github/skills/lending-update-api-junit-generator/scripts/extract-attributes-flexible.ps1`
3. If fails → Try: `.github/skills/lending-update-api-junit-generator/scripts/extract-attributes-alt-format.ps1`
4. If fails → Try: `.github/skills/lending-update-api-junit-generator/scripts/extract-from-csv.ps1`
5. Once attributes are extracted → Run: `.github/skills/lending-update-api-junit-generator/scripts/generate-test-skeleton.ps1`
6. After test class generated → Run: `.github/skills/lending-update-api-junit-generator/scripts/validate-coverage.ps1`

---

## Templates

The `templates/` subfolder contains:

| File | Purpose |
|---|---|
| `generic-update-request.json` | Generic template JSON for Update request payload |

The sample Update request payload JSON is also available at:
```
FLIQ-liqjava/IntegrationAPITool/artifacts/temp_generated_class/
```

This template is used as the base JSON for each test method's `getMainObjectFromJsonUpdate()` call. Each test mutates specific fields from this base template.

If no JSON exists at either location → generate from spreadsheet Update sheet attributes or from discovered Integration class fields and save to `LoanIQ/test-resources/json/{domain}/Update{BusinessObject}Integration.json`.

---

## Test Coverage Target: ~100%

The generated test class MUST achieve approximately 100% attribute coverage:

- Every attribute listed in the Update sheet of the spreadsheet has at least one dedicated test
- **MANDATORY:** Every attribute with an ATTRIBUTE_DESCRIPTION has an additional test case validating the rules/constraints mentioned in the description
- Every mandatory attribute has both positive and negative (null/invalid) tests
- Every code-table backed attribute has an invalid-value test
- Every collection field has add/modify/remove/duplicate tests
- Class metadata tests are always included (mappings, security, basicNew, etc.)
- Getter/Setter unit tests for all fields on the Integration class
- Non-updatable fields verified to be unchanged after update attempt
- Description-based tests cover all business rules, constraints, and scenarios mentioned in ATTRIBUTE_DESCRIPTION column

---

## File Placement

```
LoanIQ/
  test/
    com/misys/liq/api/rest/
      executable/
        {domain}/
          LiqAPIUpdate{Entity}IntegrationTest.java           ← Update integration tests
          lending-update-api-junit-generator.md              ← Coverage gap report
  test-resources/
    json/
      {domain}/
        Update{Entity}Integration.json                      ← JSON payload (generated if missing)
```

---

## Post Agent Run Modification

Use this prompt to **append new test cases** to an existing test class without modifying any existing code:

```text
#lending-update-api-junit-generator Business Object is '<entity-name>'. [Specification spreadsheet at: '<path>']
Strictly do not change any existing code in LiqAPIUpdate<entity-name>IntegrationTest.
Add new test cases starting from the last junit method in the existing class.
For all generated test methods, add a comment with the spreadsheet row number (if from spreadsheet)
or the source class field name (if from class inspection).
Add negative test cases wherever applicable.
Also inspect LiqAPIUpdate<entity-name>Integration and all its parent classes for additional test cases.
Generate a lending-update-api-junit-generator.md gap report under the test package only.
```

### Rules for Post Agent Run Modification

Use this prompt when you want to **append new test cases** to an already-existing `LiqAPIUpdate{BusinessObject}IntegrationTest` class without modifying any existing code.

> **Sample Prompt:** `#lending-update-api-junit-generator Business Object is 'Customer'. Specification spreadsheet at: C:\Auto\API\CreateConsolidatedCustomer_V7.xlsx`

1. **Preserve existing code** — Do NOT modify, delete, or reorder any existing test methods in `LiqAPIUpdate{BusinessObject}IntegrationTest`. Only append new test methods after the last existing `@Order` method.

2. **Append-only pattern** — Determine the highest existing `@Order` value in the class and continue numbering new test methods from `@Order(lastOrder + 1)`.

3. **Use only the Update worksheet** — Read only the `Update` sheet from the requirement spreadsheet. Ignore all other sheets.

4. **Row number comments (MANDATORY)** — Every generated test method MUST include a comment on the line immediately above the method signature indicating the spreadsheet row it was generated from:
   ```java
   // Spreadsheet row: <row-number> — <ATTRIBUTE_FIELD_NAME>   [or]   // Source: <ClassName>.java — field: <fieldName>
   @Test
   @Order(N)
   void testUpdate<AttributeName>_<scenario>() throws JsonProcessingException {
       LOG.debug("Order N - Testing Update {BusinessObject} {scenario}");
   ```

5. **Negative test cases** — Add negative test cases (null value, invalid value, boundary violation) wherever applicable for the corresponding spreadsheet attributes.

6. **MANDATORY — Error Message Assertion Pattern** — For every negative test case where `assertEquals("false", basicExecuteOutput.getSuccess())` is asserted, immediately follow it with the full error message assertion block:
   ```java
   basicExecuteOutput.getAPIMessages().forEach(message -> {
       if (message instanceof LiqAPIExceptionMessage) {
           LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
           LOG.error("Order {N} - API Exception Message: " + exceptionMessage.getMessage());
           assertEquals("{specific expected error message}", ((LiqAPIExceptionMessage) message).getMessage());
       }
   });
   ```
   Where `{N}` is the `@Order` value and `{specific expected error message}` is the exact validation error the API returns. See `LiqAPICreateConsolidatedCustomerIntegrationTest` for reference.

7. **Gap Report — UpdateJunitReport.md**

   After generating the new test methods, create (or overwrite) a gap report file at:
   ```
   LoanIQ/test/com/misys/liq/api/rest/executable/{domain}/UpdateJunitReport.md
   ```

   The report MUST contain exactly **4 columns**:

   | S.No. | Attributes | Covered (True/False) | Reason for not covered |
   |-------|------------|----------------------|------------------------|
   | 1 | {attributeName} | True / False | — / Already covered in existing junit methods / Not applicable / {specific reason} |

   - Populate one row per attribute from the `Update` worksheet.
   - Set `Covered` to `True` if at least one test method (existing or newly generated) exercises that attribute.
   - Set `Covered` to `False` and fill `Reason for not covered` if no test was generated or exists.
   - If an attribute is already covered by a pre-existing junit method, set `Covered` to `True` and set `Reason for not covered` to `Already covered in existing junit methods`.
   - Place this report **only** inside the test package folder — never in the main source tree.

---

## References

- Common coding instructions: `.github/instructions/lending-api-instructions.md`
- Update API implementation skill: `.github/skills/lending-update-api/SKILL.md`
- Example patterns: `.github/skills/lending-update-api-junit-generator/references/example.md`
- Class structure template: `.github/skills/lending-update-api-junit-generator/references/Update-test-class-structure.md`
- Scripts: `.github/skills/lending-update-api-junit-generator/scripts/`
- Templates: `.github/skills/lending-update-api-junit-generator/templates/`
