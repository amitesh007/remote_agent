# LoanIQ Update Test — Generic Class Structure

This document provides the generic pattern code structure for all LoanIQ Update integration test classes. It consolidates patterns from Deal, Facility, UpfrontFee, LoanDrawdown, LoanRepricing, LoanInterestPayment, LoanPrincipalPayment, MISCode, AdditionalFields, Primary, and ProductGuarantee update test skills.

---

## Overview

Each Update API domain generates one or two test classes:

| Test Class | Package | Purpose |
|---|---|---|
| `LiqAPIUpdate{Entity}IntegrationTest` | `test/.../rest/executable/{domain}/` | Integration tests for the update operation (database round-trips) |
| `LiqAPI{Entity}IntegrationAsReturnValueTest` | `test/.../rest/data/{domain}/` | Unit tests for the return value data class (optional, getter/setter + inner Class methods) |

---

## 1. Generic Update Integration Test Class Structure

### Imports (Common across all entities)

```java
package com.misys.liq.api.rest.executable.{domain};

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import com.sxsy.smtj.utilities.DateUtility;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.*;
```

### Class Declaration — Pattern A: Standalone Entity (invokeApiInterface style)

Use for: Deal, Facility, UpfrontFee, ProductGuarantee

```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIUpdate{Entity}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LoggerFactory.getLogger(LiqAPIUpdate{Entity}IntegrationTest.class);

    // Integration objects
    private LiqAPICreate{Entity}Integration liqAPIData;
    private LiqAPIQuery{Entity}Integration liqAPiDataQuery;
    private LiqAPIUpdate{Entity}Integration liqAPiDataUpdate;

    // Response holders
    private LiqAPIResponse basicExecuteOutput;
    private LiqAPIResponse basicExecuteQuery;
    private LiqAPIResponse basicExecuteUpdate;

    @BeforeEach
    public void setUp() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }
}
```

### Class Declaration — Pattern B: Outstanding/Transaction Entity (callBasicExecute style)

Use for: LoanDrawdown, LoanRepricing, LoanInterestPayment, LoanPrincipalPayment

```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIUpdate{Entity}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LoggerFactory.getLogger(LiqAPIUpdate{Entity}IntegrationTest.class);

    // Integration objects
    private LiqAPICreate{Entity}Integration liqAPIDataCreate;
    private LiqAPIQuery{Entity}Integration liqAPIDataQuery;
    private LiqAPIUpdate{Entity}Integration liqAPIDataUpdate;

    // Response holders (direct objects, not LiqAPIResponse)
    private LiqAPI{Entity}IntegrationAsReturnValue outputCreate;
    private LiqAPI{Entity}IntegrationAsReturnValue outputUpdate;
    private List<LiqAPI{Entity}IntegrationAsReturnValue> queryOutput;

    @BeforeEach
    public void setUp() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }
}
```

### Class Declaration — Pattern C: Owner-Based Entity (no Create operation)

Use for: MISCode, AdditionalFields

```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIUpdate{Entity}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LoggerFactory.getLogger(LiqAPIUpdate{Entity}IntegrationTest.class);

    // Integration objects
    private LiqAPIQuery{Entity}Integration liqAPIDataQuery;
    private LiqAPIUpdate{Entity}Integration liqAPiDataUpdate;

    // Response holders
    private LiqAPIResponse basicExecuteQuery;
    private LiqAPIResponse basicExecuteUpdate;

    // For unit-level getter/setter tests
    private LiqAPIUpdate{Entity}Integration update{Entity}Instance;

    @BeforeEach
    public void setUp() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
        update{Entity}Instance = new LiqAPIUpdate{Entity}Integration();
    }
}
```

### Class Declaration — Pattern D: Circle/Primary (static create + instance update)

Use for: Primary

```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIUpdate{Entity}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LoggerFactory.getLogger(LiqAPIUpdate{Entity}IntegrationTest.class);

    LiqAPIUpdate{Entity}Integration liqApiDataUpdate;
    static LiqAPICreate{Entity}Integration liqApiDataCreate;
    static LiqAPI{Entity}IntegrationAsReturnValue basicExecuteOutputCreate;

    @BeforeEach
    public void setProperties() throws JsonProcessingException {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
        liqApiDataUpdate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.UPDATE_{ENTITY}_INTEGRATION.toString(),
            LiqAPIUpdate{Entity}Integration.class);
    }
}
```

---

## 2. Mandatory Bootstrap Patterns

### 3-Step Bootstrap: CREATE → QUERY → UPDATE (Pattern A — invokeApiInterface)

```java
// ── STEP 1: CREATE ──────────────────────────────────────────────────────────
liqAPIData = getMainObjectFromJsonCreate(
    GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
    LiqAPICreate{Entity}Integration.class);
liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

// ── STEP 2: QUERY ────────────────────────────────────────────────────────────
liqAPiDataQuery = getMainObjectFromJsonQuery(
    GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
    LiqAPIQuery{Entity}Integration.class);
liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(
    ((LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteOutput.getResult()).get{IdField}());
basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

// ── STEP 3: UPDATE ───────────────────────────────────────────────────────────
liqAPiDataUpdate = getMainObjectFromJsonUpdate(
    GeneralIntegrationMapping.UPDATE_{ENTITY}_INTEGRATION.toString(),
    LiqAPIUpdate{Entity}Integration.class);
liqAPiDataUpdate.get{Entity}Identifiers().get(0).setIdentifierValue(
    ((LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteOutput.getResult()).get{IdField}());
```

### 3-Step Bootstrap: CREATE → QUERY → UPDATE (Pattern B — callBasicExecute)

```java
// ── STEP 1: CREATE ──────────────────────────────────────────────────────────
liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
    GeneralIntegrationMapping.CREATE_{ENTITY}_VALID.toString(),
    LiqAPICreate{Entity}Integration.class);
LiqApiDataUtil.callBasicValidate(liqAPIDataCreate);
liqAPIDataCreate.setParents();
liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
outputCreate = (LiqAPI{Entity}IntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqAPIDataCreate);

// ── STEP 2: QUERY ────────────────────────────────────────────────────────────
liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
    GeneralIntegrationMapping.QUERY_{ENTITY}_VALID.toString(),
    LiqAPIQuery{Entity}Integration.class);
liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
queryOutput = (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
String timestampFromQuery = LiqApiDataUtil.getUpdatedTimestampFromQuery(queryOutput,
    LiqAPI{Entity}IntegrationAsReturnValue::getUpdateTimeStamp);

// ── STEP 3: UPDATE ───────────────────────────────────────────────────────────
liqAPIDataUpdate = LiqApiDataUtil.getObjectFromJson(
    GeneralIntegrationMapping.UPDATE_{ENTITY}_VALID.toString(),
    LiqAPIUpdate{Entity}Integration.class);
liqAPIDataUpdate.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
liqAPIDataUpdate.setParents();
liqAPIDataUpdate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
```

### 2-Step Bootstrap: QUERY → UPDATE (Pattern C — Owner-Based)

```java
// ── STEP 1: QUERY ────────────────────────────────────────────────────────────
liqAPIDataQuery = getMainObjectFromJsonQuery(
    GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
    LiqAPIQuery{Entity}Integration.class);
basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataQuery);

// ── STEP 2: UPDATE ───────────────────────────────────────────────────────────
liqAPiDataUpdate = getMainObjectFromJsonUpdate(
    GeneralIntegrationMapping.UPDATE_{ENTITY}_INTEGRATION.toString(),
    LiqAPIUpdate{Entity}Integration.class);
((List<LiqAPI{Entity}IntegrationAsReturnValue>) basicExecuteQuery.getResult()).forEach(p -> {
    String dateAsFormattedString = DateUtility.getDateAsFormattedString(
        p.getUpdateTimeStamp(), "yyyy-MM-dd HH:mm:ss.S");
    liqAPiDataUpdate.setMatchUpdatedTimestamp(dateAsFormattedString);
});
```

---

## 3. Standard Test Method Categories

Every Update integration test class MUST include the following categories of tests:

### Category A: Identifier Validation Tests

```java
// Test: Missing identifier value
@Test @Order(1)
public void testUpdateWithout{Entity}IdentifierValue() throws JsonProcessingException { ... }

// Test: Non-existent entity
@Test @Order(2)
public void testUpdateWithNonExistent{Entity}() throws JsonProcessingException { ... }

// Test: Valid identifier
@Test @Order(3)
public void testUpdateWith{Entity}IdentifierById() throws JsonProcessingException { ... }
```

### Category B: If-Match Timestamp Tests

```java
// Test: Missing timestamp
@Test @Order(4)
public void testUpdateWithoutIfMatch() throws JsonProcessingException { ... }

// Test: Stale timestamp
@Test @Order(5)
public void testUpdateWithStaleIfMatch() throws JsonProcessingException { ... }

// Test: Valid timestamp
@Test @Order(6)
public void testUpdateWithCurrentIfMatch() throws JsonProcessingException { ... }
```

### Category C: Mandatory Field Tests (per attribute in spreadsheet)

```java
// For each mandatory field: positive + null + invalid tests
@Test @Order(10)
public void testUpdateWith{MandatoryField}() throws JsonProcessingException { ... }

@Test @Order(11)
public void testUpdateWithNull{MandatoryField}() throws JsonProcessingException { ... }

@Test @Order(12)
public void testUpdateWithInvalid{MandatoryField}() throws JsonProcessingException { ... }
```

### Category D: Optional Field Tests (per attribute in spreadsheet)

```java
// For each optional field: positive + boundary tests
@Test @Order(20)
public void testUpdateWith{OptionalField}() throws JsonProcessingException { ... }

@Test @Order(21)
public void testUpdate{OptionalField}Boundary() throws JsonProcessingException { ... }
```

### Category E: Collection Field Tests

```java
@Test @Order(30)
public void testUpdateWithValid{Collection}() throws JsonProcessingException { ... }

@Test @Order(31)
public void testUpdateWithDuplicate{Collection}Item() throws JsonProcessingException { ... }

@Test @Order(32)
public void testUpdateWithInvalid{Collection}Item() throws JsonProcessingException { ... }

@Test @Order(33)
public void testUpdateWith{Collection}Remove() throws JsonProcessingException { ... }
```

### Category F: Non-Updatable Field Tests

```java
@Test @Order(40)
public void testUpdate{NonUpdatableField}NotChanged() throws JsonProcessingException { ... }
```

### Category G: Class-Mapping Coverage Tests (MANDATORY — always present)

```java
@Test public void testNonPrimitiveFieldMappings() { ... }
@Test public void testNonPrimitiveFieldCollectionMappings() { ... }
@Test public void testPrimitiveFieldMappings() { ... }
@Test public void testSecurityAccessSymbol() { ... }
@Test public void testIsRest() { ... }
@Test public void testBasicNew() { ... }
@Test public void testGetJavaClass() { ... }
@Test public void testGetStSuperclass() { ... }
@Test public void testGetStClass() { ... }
```

### Category H: Getter/Setter Unit Tests (No DB interaction)

```java
// For every field on the Integration class
@Test public void test{Field}GetterSetter() { ... }
@Test public void test{Field}SetToNull() { ... }
```

---

## 4. Assertion Patterns

### Success Assertion (LiqAPIResponse)

```java
basicExecuteUpdate = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);
assertEquals("true", basicExecuteUpdate.getSuccess());
```

### Success Assertion (Direct execution)

```java
liqAPIDataUpdate.basicValidate();
outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();
Assertions.assertNotNull(outputUpdate);
Assertions.assertNotNull(outputUpdate.get{IdField}());
```

### Error Assertion (LiqAPIResponse — exact message)

```java
assertEquals("false", basicExecuteOutput.getSuccess());
basicExecuteOutput.getAPIMessages().forEach(message -> {
    assertEquals("Expected error message here.", ((LiqAPIExceptionMessage) message).getMessage());
});
```

### Error Assertion (LiqAPIResponse — partial match)

```java
assertEquals("false", basicExecuteUpdate.getSuccess());
boolean foundError = false;
for (Object message : basicExecuteUpdate.getAPIMessages()) {
    String errorMsg = ((LiqAPIExceptionMessage) message).getMessage();
    if (errorMsg.contains("Expected partial message")) {
        foundError = true;
        break;
    }
}
assertTrue(foundError, "Error message should indicate {reason}");
```

### Error Assertion (Exception thrown)

```java
Assertions.assertThrows(Exception.class, () -> {
    liqAPIDataUpdate.basicValidate();
});
```

---

## 5. File Placement Summary

```
LoanIQ/
  test/
    com/misys/liq/api/rest/
      data/
        {domain}/
          LiqAPI{Entity}IntegrationAsReturnValueTest.java   ← return value unit tests
      executable/
        {domain}/
          LiqAPIUpdate{Entity}IntegrationTest.java          ← update integration tests
```

---

## 6. JSON Fixture Mapping

Integration tests load their request payloads from JSON files mapped via `GeneralIntegrationMapping` enum:

| Operation | Enum Constant Pattern | Loader Method |
|---|---|---|
| Create | `CREATE_{ENTITY}_*` | `getMainObjectFromJsonCreate(...)` or `LiqApiDataUtil.getObjectFromJson(...)` |
| Query | `QUERY_{ENTITY}_*` | `getMainObjectFromJsonQuery(...)` or `LiqApiDataUtil.getObjectFromJson(...)` |
| Update | `UPDATE_{ENTITY}_*` | `getMainObjectFromJsonUpdate(...)` or `LiqApiDataUtil.getObjectFromJson(...)` |

The JSON files contain default valid payloads. Tests override specific fields after loading:

```java
liqAPiDataUpdate = getMainObjectFromJsonUpdate(
    GeneralIntegrationMapping.UPDATE_{ENTITY}_INTEGRATION.toString(),
    LiqAPIUpdate{Entity}Integration.class);
// Override to trigger a specific validation path
liqAPiDataUpdate.set{Field}("INVALID");
```

---

## 7. Coverage Checklist

Before completing test generation, verify:

- [ ] All mandatory attributes have positive + null + invalid tests
- [ ] All optional attributes have positive tests
- [ ] All code-table fields have invalid value tests
- [ ] All collection fields have add/modify/remove/duplicate tests
- [ ] All non-updatable fields have "not changed" verification tests
- [ ] Identifier validation tests present (null, invalid, valid per type)
- [ ] If-Match tests present (null, stale, valid)
- [ ] Class-mapping tests present (all 9 methods)
- [ ] Getter/setter tests for all fields
- [ ] Boolean field toggle tests (true/false)
- [ ] Date field boundary tests (valid, before-limit, after-limit)
- [ ] Numeric field boundary tests (valid, negative, zero, exceeding)
- [ ] Test method ordering via @Order annotation
- [ ] All methods declare `throws JsonProcessingException`
- [ ] No Mockito/PowerMock usage
- [ ] Correct import statements
