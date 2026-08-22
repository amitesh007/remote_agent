# LoanIQ Query Test — Generic Class Structure

> This document defines the generic test class structure for ALL LoanIQ Query (GET) API integration tests. It consolidates patterns from deal-get-test, facility-get-test, loandrawdown-get-test, loaninterestpayment-get-test, loanprincipalpayment-get-test, loanrepricing-get-test, primary-get-test, upfrontfee-get-test, miscode-get-test, and additionalfields-get-test skills.

---

## Class Declaration (Generic Template)

```java
package com.misys.liq.api.rest.executable.{domain};

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.constants.APICommonConstants;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import com.misys.liq.api.data.LiqAPINonPrimitiveFieldMapping;
import com.misys.liq.api.executable.LiqAPIExecutableData;
import com.sxsy.smtj.StClass;
import com.sxsy.smtj.StObject;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;

import java.util.List;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration tests for {@link LiqAPIQuery{Entity}Integration}.
 * Tests the complete flow: create entity → query entity → validate response.
 * Organized into test categories: Validation, Successful Query, 
 * Getter/Setter, Method Coverage, Edge Cases, Attribute Coverage.
 *
 * <p>Source spreadsheet: {SpreadsheetPath}, sheet: GetByID</p>
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIQuery{Entity}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPIQuery{Entity}IntegrationTest.class);

    // ─── Instance variables ─────────────────────────────────────────────
    private LiqAPICreate{Entity}Integration liqAPIData;
    private LiqAPIQuery{Entity}Integration liqAPiDataQuery;
    private LiqAPIResponse basicExecuteOutput;
    private LiqAPIResponse basicExecuteQuery;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }
}
```

---

## Alternative Skeleton (Transaction entities using LiqApiDataUtil)

```java
package com.misys.liq.api.rest.executable.{domain};

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import com.misys.liq.api.rest.constants.ErrorMessageConstants;
import com.misys.liq.api.rest.constants.TestDataConstants;
import com.misys.liq.infrastructure.utils.StringUtility;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;

import java.util.List;
import java.util.Properties;

/**
 * Integration tests for {@link LiqAPIQuery{Entity}Integration}.
 * Uses LiqApiDataUtil pattern (getObjectFromJson, callBasicValidate, callBasicExecute).
 *
 * <p>Source spreadsheet: {SpreadsheetPath}, sheet: GetByID</p>
 */
public class LiqAPIQuery{Entity}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPIQuery{Entity}IntegrationTest.class);

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }
}
```

---

## Test Category Organization

| Category | Order Range | Focus | Required |
|----------|-------------|-------|----------|
| **A: Validation Tests** | 1-10 | Input validation, null checks, required fields | YES |
| **B: Successful Query Tests** | 11-25 | Happy path scenarios, data retrieval | YES |
| **C: Getter/Setter Tests** | 21-30 | Field accessors, persistence | YES |
| **D: Method Coverage Tests** | 31-45 | Inner class, security, metadata | YES |
| **E: Edge Cases** | 46-55 | Special scenarios, exceptions | YES |
| **F: Attribute Coverage Tests** | 56+ | All spreadsheet attributes | YES |

---

## Category A: Validation Tests (Orders 1-10)

```java
// ════════════════════════════════════════════════════════════════════════
// Category A: Validation Tests (Orders 1-10)
// ════════════════════════════════════════════════════════════════════════

@Test
@Order(1)
public void testQueryWithoutIdentifier() throws JsonProcessingException {
    LOG.debug("Test: Query without identifier - START");
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.set{Entity}Identifier(null);
    
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertNotNull(basicExecuteQuery, "Response should not be null");
    assertEquals("false", basicExecuteQuery.getSuccess(), "Execution should fail");
    basicExecuteQuery.getAPIMessages().forEach(message -> {
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage());
        LOG.debug("Error message: {}", ((LiqAPIExceptionMessage) message).getMessage());
    });
    
    LOG.debug("Test: Query without identifier - END");
}

@Test
@Order(2)
public void testQueryWithInvalidIdentifierType() throws JsonProcessingException {
    LOG.debug("Test: Query with invalid identifier type - START");
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierType("INVALID");
    
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertNotNull(basicExecuteQuery, "Response should not be null");
    assertEquals("false", basicExecuteQuery.getSuccess(), "Execution should fail");
    
    LOG.debug("Test: Query with invalid identifier type - END");
}

@Test
@Order(3)
public void testQueryWithNullIdentifierValue() throws JsonProcessingException {
    LOG.debug("Test: Query with null identifier value - START");
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(null);
    
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertNotNull(basicExecuteQuery, "Response should not be null");
    assertEquals("false", basicExecuteQuery.getSuccess(), "Execution should fail");
    
    LOG.debug("Test: Query with null identifier value - END");
}

@Test
@Order(4)
public void testQueryNonExistentEntity() throws JsonProcessingException {
    LOG.debug("Test: Query non-existent entity - START");
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue("NON_EXISTENT_ID_7987789");
    
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertNotNull(basicExecuteQuery, "Response should not be null");
    assertEquals("false", basicExecuteQuery.getSuccess(), "Execution should fail");
    
    LOG.debug("Test: Query non-existent entity - END");
}

@Test
@Order(5)
public void testBasicValidateCallsIdentifierValidate() throws JsonProcessingException {
    LOG.debug("Test: basicValidate calls identifier validate - START");
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.basicValidate();
    assertNotNull(liqAPiDataQuery);
    
    LOG.debug("Test: basicValidate calls identifier validate - END");
}

@Test
@Order(6)
public void testQueryHandlesNullPointerException() throws JsonProcessingException {
    LOG.debug("Test: Query handles NullPointerException - START");
    
    liqAPiDataQuery = new LiqAPIQuery{Entity}Integration();
    liqAPiDataQuery.set{Entity}Identifier(null);
    assertThrows(Exception.class, () -> liqAPiDataQuery.basicValidate());
    
    LOG.debug("Test: Query handles NullPointerException - END");
}

@Test
@Order(7)
public void testQueryWithEmptyIdentifierValue() throws JsonProcessingException {
    LOG.debug("Test: Query with empty identifier value - START");
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue("");
    
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertNotNull(basicExecuteQuery, "Response should not be null");
    assertEquals("false", basicExecuteQuery.getSuccess(), "Execution should fail");
    
    LOG.debug("Test: Query with empty identifier value - END");
}
```

---

## Category B: Successful Query Tests (Orders 11-25)

```java
// ════════════════════════════════════════════════════════════════════════
// Category B: Successful Query Tests (Orders 11-25)
// ════════════════════════════════════════════════════════════════════════

@Test
@Order(11)
public void testSuccessfulQueryById() throws JsonProcessingException {
    LOG.debug("Test: Successful query by ID - START");
    
    // STEP 1: CREATE seed entity
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPICreate{Entity}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    
    String entityId = ((LiqAPI{Entity}IntegrationAsReturnValue) 
        basicExecuteOutput.getResult()).get{Entity}Id();
    
    // STEP 2: QUERY
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(entityId);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertEquals("true", basicExecuteQuery.getSuccess());
    assertNotNull(basicExecuteQuery.getResult());
    
    LOG.debug("Test: Successful query by ID - END");
}

@Test
@Order(12)
public void testQueryReturnsCorrectEntityData() throws JsonProcessingException {
    LOG.debug("Test: Query returns correct entity data - START");
    
    // CREATE → QUERY bootstrap
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPICreate{Entity}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    
    String entityId = ((LiqAPI{Entity}IntegrationAsReturnValue) 
        basicExecuteOutput.getResult()).get{Entity}Id();
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(entityId);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertNotNull(basicExecuteQuery.getResult());
    LiqAPI{Entity}IntegrationAsReturnValue returnValue = 
        (LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteQuery.getResult();
    assertNotNull(returnValue);
    assertNotNull(returnValue.get{Entity}Id());
    assertNotNull(returnValue.getUpdateTimeStamp());
    
    LOG.debug("Test: Query returns correct entity data - END");
}

@Test
@Order(13)
public void testQueryReturnsUpdateTimeStamp() throws JsonProcessingException {
    LOG.debug("Test: Query returns updateTimeStamp - START");
    
    // CREATE → QUERY bootstrap
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPICreate{Entity}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    
    String entityId = ((LiqAPI{Entity}IntegrationAsReturnValue) 
        basicExecuteOutput.getResult()).get{Entity}Id();
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(entityId);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    LiqAPI{Entity}IntegrationAsReturnValue returnValue = 
        (LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteQuery.getResult();
    assertNotNull(returnValue.getUpdateTimeStamp(), "updateTimeStamp should not be null");
    
    LOG.debug("Test: Query returns updateTimeStamp - END");
}
```

---

## Category C: Getter/Setter Tests (Orders 21-30)

```java
// ════════════════════════════════════════════════════════════════════════
// Category C: Getter/Setter Tests (Orders 21-30)
// ════════════════════════════════════════════════════════════════════════

@Test
@Order(21)
public void testIdentifierGetterSetter() {
    LOG.debug("Test: Identifier getter/setter - START");
    
    liqAPiDataQuery = new LiqAPIQuery{Entity}Integration();
    LiqAPI{Entity}Identifier identifier = 
        (LiqAPI{Entity}Identifier) LiqAPI{Entity}Identifier.clazz.basicNew();
    identifier.setIdentifierType("ID");
    identifier.setIdentifierValue("TEST123");
    
    liqAPiDataQuery.set{Entity}Identifier(identifier);
    LiqAPI{Entity}Identifier result = liqAPiDataQuery.get{Entity}Identifier();
    
    assertNotNull(result, "Identifier should not be null");
    assertEquals("ID", result.getIdentifierType());
    assertEquals("TEST123", result.getIdentifierValue());
    
    LOG.debug("Test: Identifier getter/setter - END");
}

@Test
@Order(22)
public void testSetIdentifierWithNull() {
    LOG.debug("Test: Set identifier with null - START");
    
    liqAPiDataQuery = new LiqAPIQuery{Entity}Integration();
    liqAPiDataQuery.set{Entity}Identifier(null);
    assertNull(liqAPiDataQuery.get{Entity}Identifier());
    
    LOG.debug("Test: Set identifier with null - END");
}

@Test
@Order(23)
public void testIdentifierPersistence() {
    LOG.debug("Test: Identifier persistence - START");
    
    liqAPiDataQuery = new LiqAPIQuery{Entity}Integration();
    
    LiqAPI{Entity}Identifier identifier1 = 
        (LiqAPI{Entity}Identifier) LiqAPI{Entity}Identifier.clazz.basicNew();
    identifier1.setIdentifierValue("VALUE1");
    liqAPiDataQuery.set{Entity}Identifier(identifier1);
    assertEquals("VALUE1", liqAPiDataQuery.get{Entity}Identifier().getIdentifierValue());
    
    LiqAPI{Entity}Identifier identifier2 = 
        (LiqAPI{Entity}Identifier) LiqAPI{Entity}Identifier.clazz.basicNew();
    identifier2.setIdentifierValue("VALUE2");
    liqAPiDataQuery.set{Entity}Identifier(identifier2);
    assertEquals("VALUE2", liqAPiDataQuery.get{Entity}Identifier().getIdentifierValue());
    
    LOG.debug("Test: Identifier persistence - END");
}
```

---

## Category D: Method Coverage Tests (Orders 31-45)

```java
// ════════════════════════════════════════════════════════════════════════
// Category D: Method Coverage Tests (Orders 31-45)
// ════════════════════════════════════════════════════════════════════════

@Test
@Order(31)
public void testSecurityAccessSymbol() {
    LOG.debug("Test: Security access symbol - START");
    
    liqAPiDataQuery = new LiqAPIQuery{Entity}Integration();
    String symbol = liqAPiDataQuery.securityAccessSymbol();
    
    assertNotNull(symbol, "Security access symbol should not be null");
    assertEquals("Query{Entity}Integration", symbol);
    assertEquals(symbol, LiqAPIQuery{Entity}Integration.clazz.securityAccessSymbol());
    
    LOG.debug("Test: Security access symbol - END");
}

@Test
@Order(32)
public void testValidateLicense() {
    LOG.debug("Test: Validate license - START");
    
    liqAPiDataQuery = new LiqAPIQuery{Entity}Integration();
    LiqAPIExecutableData result = liqAPiDataQuery.validateLicense();
    
    assertNotNull(result, "Validate license should return this");
    assertEquals(liqAPiDataQuery, result);
    
    LOG.debug("Test: Validate license - END");
}

@Test
@Order(33)
public void testBasicNew() {
    LOG.debug("Test: Basic new - START");
    
    StObject newObject = LiqAPIQuery{Entity}Integration.clazz.basicNew();
    
    assertNotNull(newObject, "basicNew should create new instance");
    assertTrue(newObject instanceof LiqAPIQuery{Entity}Integration);
    
    LOG.debug("Test: Basic new - END");
}

@Test
@Order(34)
public void testGetJavaClass() {
    LOG.debug("Test: Get Java class - START");
    
    java.lang.Class javaClass = LiqAPIQuery{Entity}Integration.clazz.getJavaClass();
    
    assertNotNull(javaClass);
    assertEquals(LiqAPIQuery{Entity}Integration.class, javaClass);
    
    LOG.debug("Test: Get Java class - END");
}

@Test
@Order(35)
public void testGetStClass() {
    LOG.debug("Test: Get StClass - START");
    
    liqAPiDataQuery = new LiqAPIQuery{Entity}Integration();
    StClass stClass = liqAPiDataQuery.getStClass();
    
    assertNotNull(stClass);
    assertEquals(LiqAPIQuery{Entity}Integration.clazz, stClass);
    
    LOG.debug("Test: Get StClass - END");
}

@Test
@Order(36)
public void testGetStSuperclass() {
    LOG.debug("Test: Get St superclass - START");
    
    StClass superclass = LiqAPIQuery{Entity}Integration.clazz.getStSuperclass();
    
    assertNotNull(superclass);
    assertEquals(LiqAPIExecutableData.clazz, superclass);
    
    LOG.debug("Test: Get St superclass - END");
}

@Test
@Order(37)
public void testIsRest() {
    LOG.debug("Test: Is REST - START");
    
    assertTrue(LiqAPIQuery{Entity}Integration.clazz.isRest());
    
    LOG.debug("Test: Is REST - END");
}

@Test
@Order(38)
public void testNonPrimitiveFieldMappings() {
    LOG.debug("Test: Non-primitive field mappings - START");
    
    List mappings = LiqAPIQuery{Entity}Integration.clazz.nonPrimitiveFieldMappings();
    assertNotNull(mappings, "Non-primitive field mappings should not be null");
    assertFalse(mappings.isEmpty(), "Non-primitive field mappings should not be empty");
    
    LOG.debug("Test: Non-primitive field mappings - END");
}

@Test
@Order(39)
public void testPrimitiveFieldMappings() {
    LOG.debug("Test: Primitive field mappings - START");
    
    List mappings = LiqAPIQuery{Entity}Integration.clazz.primitiveFieldMappings();
    assertNotNull(mappings, "Primitive field mappings should not be null");
    
    LOG.debug("Test: Primitive field mappings - END");
}

@Test
@Order(40)
public void testResponseClassMappings() {
    LOG.debug("Test: Response class mappings - START");
    
    assertNotNull(LiqAPI{Entity}IntegrationAsReturnValue.clazz.primitiveFieldMappings());
    assertNotNull(LiqAPI{Entity}IntegrationAsReturnValue.clazz.nonPrimitiveFieldMappings());
    assertNotNull(LiqAPI{Entity}IntegrationAsReturnValue.clazz.nonPrimitiveFieldCollectionMappings());
    assertTrue(LiqAPI{Entity}IntegrationAsReturnValue.clazz.isRest());
    
    LOG.debug("Test: Response class mappings - END");
}

@Test
@Order(41)
public void testReturnType() {
    LOG.debug("Test: Return type - START");
    
    assertNotNull(LiqAPIQuery{Entity}Integration.clazz.getReturnType());
    
    LOG.debug("Test: Return type - END");
}

@Test
@Order(42)
public void testIsIntegrationAPI() {
    LOG.debug("Test: isIntegrationAPI - START");
    
    liqAPiDataQuery = new LiqAPIQuery{Entity}Integration();
    assertTrue(liqAPiDataQuery.isIntegrationAPI());
    
    LOG.debug("Test: isIntegrationAPI - END");
}
```

---

## Category E: Edge Cases & Error Handling (Orders 46-55)

```java
// ════════════════════════════════════════════════════════════════════════
// Category E: Edge Cases & Error Handling (Orders 46-55)
// ════════════════════════════════════════════════════════════════════════

@Test
@Order(46)
public void testQueryWithSpecialCharactersInIdentifierValue() throws JsonProcessingException {
    LOG.debug("Test: Query with special characters - START");
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue("TEST@#$%");
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertNotNull(basicExecuteQuery);
    assertEquals("false", basicExecuteQuery.getSuccess());
    
    LOG.debug("Test: Query with special characters - END");
}

@Test
@Order(47)
public void testQueryWithVeryLongIdentifierValue() throws JsonProcessingException {
    LOG.debug("Test: Query with very long identifier value - START");
    
    String longValue = "A".repeat(500);
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(longValue);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertNotNull(basicExecuteQuery);
    assertEquals("false", basicExecuteQuery.getSuccess());
    
    LOG.debug("Test: Query with very long identifier value - END");
}

@Test
@Order(48)
public void testMultipleConsecutiveQueries() throws JsonProcessingException {
    LOG.debug("Test: Multiple consecutive queries - START");
    
    // CREATE seed
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPICreate{Entity}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    
    String entityId = ((LiqAPI{Entity}IntegrationAsReturnValue) 
        basicExecuteOutput.getResult()).get{Entity}Id();
    
    // Query 1
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(entityId);
    LiqAPIResponse query1 = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    // Query 2 (same entity)
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(entityId);
    LiqAPIResponse query2 = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    assertEquals("true", query1.getSuccess());
    assertEquals("true", query2.getSuccess());
    
    LOG.debug("Test: Multiple consecutive queries - END");
}
```

---

## Category F: Attribute Coverage Tests (Orders 56+)

> Generate one test per output attribute from the spreadsheet's GetByID sheet.

### Mandatory Primitive Attributes

```java
@Test
@Order(56)
public void testQueryReturns{AttributeName}() throws JsonProcessingException {
    LOG.debug("Test: Query returns {attributeName} - START");
    
    // CREATE → QUERY bootstrap
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPICreate{Entity}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    
    String entityId = ((LiqAPI{Entity}IntegrationAsReturnValue) 
        basicExecuteOutput.getResult()).get{Entity}Id();
    
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(entityId);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    
    LiqAPI{Entity}IntegrationAsReturnValue returnValue = 
        (LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteQuery.getResult();
    
    assertNotNull(returnValue.get{AttributeName}(), 
        "{attributeName} should not be null for mandatory field");
    
    LOG.debug("Test: Query returns {attributeName} - END");
}
```

### Optional Primitive Attributes

```java
@Test
@Order(57)
public void testQueryReturns{OptionalAttributeName}() throws JsonProcessingException {
    LOG.debug("Test: Query returns {optionalAttributeName} - START");
    
    // CREATE → QUERY bootstrap (same as above)
    // ...
    
    LiqAPI{Entity}IntegrationAsReturnValue returnValue = 
        (LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteQuery.getResult();
    
    // Optional field — verify getter is accessible (may be null)
    returnValue.get{OptionalAttributeName}();
    
    LOG.debug("Test: Query returns {optionalAttributeName} - END");
}
```

### Non-Primitive Collection Attributes

```java
@Test
@Order(58)
public void testQueryReturns{CollectionName}() throws JsonProcessingException {
    LOG.debug("Test: Query returns {collectionName} - START");
    
    // CREATE → QUERY bootstrap (with a JSON that populates the collection)
    // ...
    
    LiqAPI{Entity}IntegrationAsReturnValue returnValue = 
        (LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteQuery.getResult();
    
    assertNotNull(returnValue.get{CollectionName}(), 
        "{collectionName} should not be null");
    assertFalse(returnValue.get{CollectionName}().isEmpty(),
        "{collectionName} should contain at least one element");
    
    // Verify elements have expected sub-fields
    returnValue.get{CollectionName}().forEach(item -> {
        assertNotNull(item.get{SubFieldName}());
    });
    
    LOG.debug("Test: Query returns {collectionName} - END");
}
```

### Non-Primitive Single Attributes

```java
@Test
@Order(59)
public void testQueryReturns{NestedObjectName}() throws JsonProcessingException {
    LOG.debug("Test: Query returns {nestedObjectName} - START");
    
    // CREATE → QUERY bootstrap (with a JSON that populates the nested object)
    // ...
    
    LiqAPI{Entity}IntegrationAsReturnValue returnValue = 
        (LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteQuery.getResult();
    
    assertNotNull(returnValue.get{NestedObjectName}(), 
        "{nestedObjectName} should not be null");
    // Verify sub-fields
    assertNotNull(returnValue.get{NestedObjectName}().get{SubField}());
    
    LOG.debug("Test: Query returns {nestedObjectName} - END");
}
```

---

## Transaction Entity Specific Patterns

For transaction-based entities (LoanDrawdown, LoanInterestPayment, etc.) that use `LiqApiDataUtil`:

```java
@SuppressWarnings("unchecked")
@Test
public void testQueryResponseHas{FieldName}() throws JsonProcessingException {
    LOG.debug("Test: Response has {fieldName} - START");
    
    LiqAPIQuery{Entity}Integration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_{ENTITY}_VALID.toString(),
        LiqAPIQuery{Entity}Integration.class);
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    
    List<LiqAPI{Entity}IntegrationAsReturnValue> output =
        (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    
    Assertions.assertNotNull(output);
    Assertions.assertFalse(output.isEmpty());
    Assertions.assertNotNull(output.get(0).get{FieldName}());
    
    LOG.debug("Test: Response has {fieldName} - END");
}
```

---

## Helper Method Patterns

### Assert Query Success

```java
private void assertQuerySuccess(LiqAPIResponse response) {
    assertNotNull(response, "Response should not be null");
    assertEquals("true", response.getSuccess(), "Query should succeed");
    assertNotNull(response.getResult(), "Result should not be null");
}
```

### Assert Query Failure

```java
private void assertQueryFailure(LiqAPIResponse response) {
    assertNotNull(response, "Response should not be null");
    assertEquals("false", response.getSuccess(), "Query should fail");
    assertNotNull(response.getAPIMessages(), "API messages should be present");
    response.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
}
```

---

## Import Block (Complete)

```java
import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.constants.APICommonConstants;
import com.misys.liq.api.data.LiqAPINonPrimitiveFieldMapping;
import com.misys.liq.api.executable.LiqAPIExecutableData;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import com.sxsy.smtj.StClass;
import com.sxsy.smtj.StObject;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;

import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.*;
```
