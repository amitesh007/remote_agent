# Generic Create Test Class Structure

This file defines the generic class structure pattern consolidated from all `*-create-test` skills. When generating a new Create test class, select the appropriate structure variant based on the business object's execution model.

---

## Variant A: `invokeApiInterface` Pattern

**Used by**: UpfrontFee, Deal, Facility, ProductGuarantee

This is the most common pattern. The test class uses `invokeApiInterface()` which returns a `LiqAPIResponse` wrapper.

```java
package com.misys.liq.api.rest.executable.{domain};

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
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

    // ═══════════════════════════════════════════════════════════════
    // SECTION 1: Mandatory Validation Tests (@Order)
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(1)
    public void testCreate{BusinessObject}WithoutIdempotencyKey() throws JsonProcessingException {
        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        // Deliberately do NOT set idempotencyKey
        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
        assertEquals("false", basicExecuteOutput.getSuccess());
        basicExecuteOutput.getAPIMessages().forEach(message ->
            assertEquals("The idempotencyKey is mandatory for POST calls.",
                ((LiqAPIExceptionMessage) message).getMessage()));
    }

    @Test
    @Order(2)
    public void testCreate{BusinessObject}Without{MandatoryField}() throws JsonProcessingException {
        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIData.set{MandatoryField}(null);
        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
        assertEquals("false", basicExecuteOutput.getSuccess());
        basicExecuteOutput.getAPIMessages().forEach(message ->
            assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 2: Invalid Value Tests (@Order continues)
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(10)
    public void testCreate{BusinessObject}WithInvalid{Field}() throws JsonProcessingException {
        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIData.set{Field}("INVALID_VALUE");
        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
        assertEquals("false", basicExecuteOutput.getSuccess());
        basicExecuteOutput.getAPIMessages().forEach(message ->
            assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 3: Positive / Happy-Path Tests (no @Order)
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testCreate{BusinessObject}WithAllMandatoryFields() throws JsonProcessingException {
        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
        assertEquals("true", basicExecuteOutput.getSuccess());
        LiqAPI{BusinessObject}IntegrationAsReturnValue response =
            (LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteOutput.getResult();
        assertNotNull(response);
        assertNotNull(response.get{IdField}());
    }

    @Test
    public void testCreate{BusinessObject}With{OptionalField}() throws JsonProcessingException {
        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.{OPTIONAL_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
        assertEquals("true", basicExecuteOutput.getSuccess());
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 4: Class-Mapping Coverage Tests (mandatory)
    // ═══════════════════════════════════════════════════════════════

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
}
```

---

## Variant B: `callBasicValidate` + `setParents` + `callBasicExecute` Pattern

**Used by**: LoanDrawdown

This pattern requires parent linkage to be set before execution. Response is cast directly to the return value class.

```java
package com.misys.liq.api.rest.executable.outstanding.drawdown;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.data.outstanding.drawdown.LiqAPILoanDrawdownIntegrationAsReturnValue;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import java.util.Properties;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.Assertions;
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
    private LiqAPI{BusinessObject}IntegrationAsReturnValue basicExecuteOutput;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 1: Positive Test (Validate → SetParents → Execute)
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(1)
    public void testCreate{BusinessObject}Valid() throws JsonProcessingException {
        LOG.debug("In testCreate{BusinessObject}Valid() - START");

        liqAPIData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        // Generate unique identifier (if applicable)
        int randomSixDigit = 100000 + (int) (Math.random() * 900000);
        liqAPIData.getOutstandingIdentifier().setIdentifierValue("BORROWER " + randomSixDigit);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        LiqApiDataUtil.callBasicValidate(liqAPIData);
        liqAPIData.setParents();

        basicExecuteOutput = (LiqAPI{BusinessObject}IntegrationAsReturnValue)
            LiqApiDataUtil.callBasicExecute(liqAPIData);

        Assertions.assertNotNull(basicExecuteOutput);
        Assertions.assertNotNull(basicExecuteOutput.getLoanTransactionId());
        Assertions.assertNotNull(basicExecuteOutput.getLoanId());
        Assertions.assertNotNull(basicExecuteOutput.getUpdateTimeStamp());

        LOG.debug("testCreate{BusinessObject}Valid - ENDS");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 2: Negative Test (Exception-Based)
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(2)
    public void testCreate{BusinessObject}WithDuplicateAlias() throws JsonProcessingException {
        LOG.debug("In testCreate{BusinessObject}WithDuplicateAlias() - START");

        liqAPIData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.getOutstandingIdentifier().setIdentifierValue(TestDataConstants.EXISTING_LOAN_ALIAS);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        LiqApiDataUtil.callBasicValidate(liqAPIData);
        liqAPIData.setParents();

        try {
            basicExecuteOutput = (LiqAPI{BusinessObject}IntegrationAsReturnValue)
                LiqApiDataUtil.callBasicExecute(liqAPIData);
        } catch (Exception e) {
            Assertions.assertEquals(
                String.format(ErrorMessageConstants.ALIAS_BORROWER_ALREADY_IN_USE,
                    TestDataConstants.EXISTING_LOAN_ALIAS),
                e.getMessage());
        }

        LOG.debug("testCreate{BusinessObject}WithDuplicateAlias - ENDS");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 3: Class-Mapping Coverage
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testNonPrimitiveFieldMappings() {
        assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings());
    }

    @Test
    public void testPrimitiveFieldMappings() {
        assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.primitiveFieldMappings());
    }

    @Test
    public void testSecurityAccessSymbol() throws JsonProcessingException {
        LiqAPICreate{BusinessObject}Integration data = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        assertEquals(TestDataConstants.SECURITY_ACCESS_SYMBOL_CREATE_{UPPER_NAME},
            data.securityAccessSymbol());
    }

    @Test
    public void testReturnType() {
        assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.getReturnType());
    }

    @Test
    public void testIsRest() {
        assertTrue(LiqAPICreate{BusinessObject}Integration.clazz.isRest());
    }
}
```

---

## Variant C: `callBasicValidate` + `callBasicExecute` Pattern (Exception-based validation)

**Used by**: Primary (Circle)

This pattern uses exception-based validation. Tests verify behaviour by catching exceptions from `callBasicValidate()` or `callBasicExecute()`.

```java
package com.misys.liq.api.rest.executable.circle;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.api.rest.constants.APICommonConstants;
import com.misys.liq.api.rest.constants.ErrorMessageConstants;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import java.util.Properties;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPICreate{BusinessObject}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPICreate{BusinessObject}IntegrationTest.class);

    LiqAPICreate{BusinessObject}Integration liqApiDataCreate;

    @BeforeEach
    public void setProperties() throws JsonProcessingException {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
        liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 1: Validation Exception Tests (@Order)
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(1)
    public void testBasicValidateWithout{RequiredField}() throws JsonProcessingException {
        liqApiDataCreate.set{RequiredField}(null);
        try {
            LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
        } catch (Exception e) {
            assertEquals(ErrorMessageConstants.{FIELD}_REQUIRED, e.getMessage());
        }
    }

    @Test
    @Order(2)
    public void testBasicValidateWithInvalid{Field}() throws JsonProcessingException {
        liqApiDataCreate.get{NestedObject}().set{Field}("INVALID_VALUE");
        try {
            LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
        } catch (Exception e) {
            assertTrue(e.getMessage().contains("is not a code in table"));
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 2: Execute with Exception Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(10)
    public void testCreate{BusinessObject}OnInvalidState() throws JsonProcessingException {
        liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{INVALID_STATE_ENUM}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
        liqApiDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        try {
            LiqApiDataUtil.callBasicExecute(liqApiDataCreate);
        } catch (Exception e) {
            assertEquals("{Expected error message}", e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 3: Positive Execute Test
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(13)
    public void testBasicExecute() throws JsonProcessingException {
        liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        LOG.debug("In testBasicExecute - START");
        LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
        liqApiDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        LiqAPI{ReturnValue}IntegrationAsReturnValue basicExecuteOutput =
            (LiqAPI{ReturnValue}IntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqApiDataCreate);
        assertNotNull(basicExecuteOutput.get{IdField}());
        LOG.debug("In testBasicExecute - END");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 4: Class-Mapping Coverage (Extended)
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testBasicNew() {
        Assertions.assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.basicNew());
        Assertions.assertTrue(
            LiqAPICreate{BusinessObject}Integration.clazz.basicNew() instanceof LiqAPICreate{BusinessObject}Integration);
    }

    @Test
    public void testJavaClass() {
        Assertions.assertEquals(LiqAPICreate{BusinessObject}Integration.class,
            LiqAPICreate{BusinessObject}Integration.clazz.getJavaClass());
    }

    @Test
    public void testStSuperclass() {
        Assertions.assertEquals(LiqAPICreate{BusinessObject}.clazz,
            LiqAPICreate{BusinessObject}Integration.clazz.getStSuperclass());
    }

    @Test
    public void testNonPrimitiveFieldCollectionMappings() {
        Assertions.assertNotNull(
            LiqAPICreate{BusinessObject}Integration.clazz.nonPrimitiveFieldCollectionMappings());
    }

    @Test
    public void testNonPrimitiveFieldMappings() {
        Assertions.assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings());
    }

    @Test
    public void testPrimitiveFieldMappings() {
        Assertions.assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.primitiveFieldMappings());
        Assertions.assertFalse(LiqAPICreate{BusinessObject}Integration.clazz.primitiveFieldMappings().isEmpty());
    }

    @Test
    public void testIsRest() {
        Assertions.assertTrue(LiqAPICreate{BusinessObject}Integration.clazz.isRest());
    }

    @Test
    public void testStclass() {
        Assertions.assertEquals(LiqAPICreate{BusinessObject}Integration.clazz, liqApiDataCreate.getStClass());
    }

    @Test
    public void testValidateLicense() {
        Assertions.assertNotNull(liqApiDataCreate.validateLicense());
    }

    @Test
    public void testSecurityAccessSymbol() {
        Assertions.assertEquals(APICommonConstants.SECURITY_ACCESS_SYMBOL_{CONSTANT},
            liqApiDataCreate.securityAccessSymbol());
    }

    @Test
    public void testIsIntegrationAPI() {
        Assertions.assertTrue(liqApiDataCreate.isIntegrationAPI());
    }
}
```

---

## Variant D: `basicValidate` + `basicExecute` Pattern (Instance methods)

**Used by**: LoanInterestPayment, LoanPrincipalPayment, LoanRepricing

This pattern calls `basicValidate()` and `basicExecute()` directly on the data object instance (not static utility methods).

```java
package com.misys.liq.api.rest.executable.outstanding.{subdomain};

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import java.util.Properties;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.Assertions;
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
    private LiqAPI{BusinessObject}IntegrationAsReturnValue output;

    @BeforeEach
    public void setUp() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 1: Positive Test (Instance Validate + Execute)
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(1)
    public void testCreate{BusinessObject}Valid() throws JsonProcessingException {
        LOG.debug("In testCreate{BusinessObject}Valid() - START");

        liqAPIData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIData.basicValidate();
        output = (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIData.basicExecute();

        Assertions.assertNotNull(output);
        Assertions.assertNotNull(output.getLoanTransactionId());
        Assertions.assertNotNull(output.getUpdateTimeStamp());
        Assertions.assertEquals("PEND", output.getStatusCode());

        LOG.debug("testCreate{BusinessObject}Valid - ENDS");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 2: Negative Test (Try-Catch with fail())
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(2)
    public void testCreate{BusinessObject}Without{MandatoryField}() throws JsonProcessingException {
        LOG.debug("In testCreate{BusinessObject}Without{MandatoryField}() - START");

        liqAPIData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.set{MandatoryField}(null);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());

        try {
            liqAPIData.basicValidate();
            output = (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIData.basicExecute();
            Assertions.fail("Expected exception for null {mandatoryField}");
        } catch (Exception e) {
            Assertions.assertNotNull(e.getMessage());
            LOG.debug("Expected error: {}", e.getMessage());
        }

        LOG.debug("testCreate{BusinessObject}Without{MandatoryField} - ENDS");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 3: Boolean Indicator Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testCreate{BusinessObject}With{BooleanField}True() throws JsonProcessingException {
        liqAPIData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIData.set{BooleanField}(true);
        liqAPIData.basicValidate();
        output = (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIData.basicExecute();
        assertNotNull(output);
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 4: Code Table / Enum Validation Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testCreate{BusinessObject}WithInvalid{CodeField}() throws JsonProcessingException {
        liqAPIData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIData.set{CodeField}("INVALID");
        try {
            liqAPIData.basicValidate();
            liqAPIData.basicExecute();
            fail("Expected exception for invalid {codeField}");
        } catch (Exception e) {
            assertNotNull(e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 5: Class-Mapping Coverage
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testNonPrimitiveFieldMappings() {
        assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings());
    }

    @Test
    public void testPrimitiveFieldMappings() {
        assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.primitiveFieldMappings());
    }

    @Test
    public void testSecurityAccessSymbol() {
        assertEquals("Create{BusinessObject}Integration",
            LiqAPICreate{BusinessObject}Integration.clazz.securityAccessSymbol());
    }

    @Test
    public void testIsRest() {
        assertTrue(LiqAPICreate{BusinessObject}Integration.clazz.isRest());
    }

    @Test
    public void testGetStClass() throws JsonProcessingException {
        LiqAPICreate{BusinessObject}Integration data = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        assertNotNull(data.getStClass());
    }

    @Test
    public void testReturnType() {
        assertNotNull(LiqAPICreate{BusinessObject}Integration.clazz.getReturnType());
    }
}
```

---

## Variant D-List: `basicValidate` + `basicExecute` → List Return

**Used by**: LoanInterestPayment (returns `List<ReturnValue>`)

```java
    @Test
    @Order(1)
    public void testCreate{BusinessObject}Valid() throws JsonProcessingException {
        LOG.debug("In testCreate{BusinessObject}Valid() - START");

        liqAPIData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIData.basicValidate();
        List<LiqAPI{BusinessObject}IntegrationAsReturnValue> results =
            (List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) liqAPIData.basicExecute();

        Assertions.assertNotNull(results);
        Assertions.assertFalse(results.isEmpty());
        output = results.get(0);
        Assertions.assertNotNull(output.getLoanTransactionId());
        Assertions.assertNotNull(output.getUpdateTimeStamp());
        Assertions.assertEquals("PEND", output.getStatusCode());

        LOG.debug("testCreate{BusinessObject}Valid - ENDS");
    }
```

---

## Variant Selection Guide

| Criterion | Variant |
|---|---|
| Uses `invokeApiInterface()` returning `LiqAPIResponse` | **A** (UpfrontFee, Deal, Facility, ProductGuarantee) |
| Requires `setParents()` before execute | **B** (LoanDrawdown) |
| Exception-based validation via `callBasicValidate()` static method | **C** (Primary) |
| Instance `basicValidate()` + `basicExecute()` direct cast | **D** (LoanPrincipalPayment, LoanRepricing) |
| Instance `basicValidate()` + `basicExecute()` list return | **D-List** (LoanInterestPayment) |

---

## Common Sections (All Variants)

### Import Block (minimum required)

```java
import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import java.util.Properties;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
```

### Additional Imports (conditional)

```java
// For Variant A (invokeApiInterface pattern):
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;

// For Variant C (ErrorMessageConstants):
import com.misys.liq.api.rest.constants.APICommonConstants;
import com.misys.liq.api.rest.constants.ErrorMessageConstants;

// For date tests:
import com.misys.liq.api.rest.util.DateUtility;
import java.util.Date;

// For BigDecimal tests:
import java.math.BigDecimal;

// For List returns (Variant D-List):
import java.util.List;
```

### @BeforeEach Variants

```java
// Standard (most common):
@BeforeEach
public void setProperties() {
    Properties props = System.getProperties();
    props.setProperty("RestServices", "Y");
}

// With IntegrationAPIMode (Deal):
@BeforeEach
public void setProperties() {
    Properties props = System.getProperties();
    props.setProperty("RestServices", "Y");
    LoanIQ.currentSession().setIntegrationAPIMode(Boolean.TRUE);
}

// With pre-loaded data (Primary):
@BeforeEach
public void setProperties() throws JsonProcessingException {
    Properties props = System.getProperties();
    props.setProperty("RestServices", "Y");
    liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.{PRIMARY_ENUM_CONSTANT}.toString(),
        LiqAPICreate{BusinessObject}Integration.class);
}
```

---

## Placeholder Reference

| Placeholder | Replace With |
|---|---|
| `{BusinessObject}` | Pascal-case name (e.g., `UpfrontFee`, `LoanDrawdown`) |
| `{domain}` | Package segment (e.g., `upfrontfee`, `outstanding.drawdown`) |
| `{subdomain}` | Sub-package (e.g., `interest`, `principal`) |
| `{PRIMARY_ENUM_CONSTANT}` | Main enum constant (e.g., `CREATE_UPFRONTFEE_TRANSACTION_WITH_AMOUNT`) |
| `{OPTIONAL_ENUM_CONSTANT}` | Feature-specific enum constant |
| `{INVALID_STATE_ENUM}` | Enum for invalid state (e.g., `CREATE_PRIMARY_CIRCLE_INTEGRATION_CLOSED_DEAL`) |
| `{MandatoryField}` | Pascal-case field name (e.g., `DealName`, `RequestedAmount`) |
| `{OptionalField}` | Optional field name |
| `{BooleanField}` | Boolean indicator field |
| `{CodeField}` | Code table field |
| `{IdField}` | Response ID method (e.g., `Id`, `DealId`, `TransactionId`, `CircleId`) |
| `{ExpectedSecuritySymbol}` | Security symbol string (e.g., `"CreateDealIntegration"`) |
| `{ReturnValue}` | Return value class base name (e.g., `Circle`, `LoanDrawdown`) |
| `{UPPER_NAME}` | Screaming snake case (e.g., `LOAN_DRAWDOWN`) |
| `{CONSTANT}` | APICommonConstants suffix (e.g., `DEAL_CREATE`, `CREATE_CIRCLE`) |
