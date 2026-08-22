# Generic Delete Test Class Structure

This file defines the generic class structure pattern consolidated from all `*-delete-test` skills. When generating a new Delete test class, select the appropriate structure variant based on the business object's execution model.

---

## Variant A: `invokeApiInterface` Pattern (with If-Match)

**Used by**: Deal, UpfrontFee, ProductGuarantee, MISCode

This is the most common pattern. The test class uses `invokeApiInterface()` which returns a `LiqAPIResponse` wrapper, and requires an If-Match timestamp from the QUERY step.

```java
package com.misys.liq.api.rest.executable.{domain};

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import com.misys.liq.utilities.DateUtility;
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
    private LiqAPIQuery{BusinessObject}Integration  liqAPiDataQuery;
    private LiqAPIDelete{BusinessObject}Integration liqAPiDataDelete;
    private LiqAPIResponse basicExecuteOutput;
    private LiqAPIResponse basicExecuteQuery;
    private LiqAPIResponse basicExecuteDelete;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
        LoanIQ.currentSession().setIntegrationAPIMode(Boolean.TRUE);
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 1: Mandatory Validation Tests (@Order 1-N)
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(1)
    public void testDeleteWithout{Identifier}Value() throws JsonProcessingException {
        LOG.debug("In testDeleteWithout{Identifier}Value - START");

        // STEP 1: CREATE
        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

        // STEP 2: QUERY
        liqAPiDataQuery = getMainObjectFromJsonQuery(
            GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
            LiqAPIQuery{BusinessObject}Integration.class);
        liqAPiDataQuery.get{Identifier}().setIdentifierValue(
            ((LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteOutput.getResult()).get{IdField}());
        basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

        // STEP 3: DELETE — mutate the field under test
        liqAPiDataDelete = getMainObjectFromJsonDelete(
            GeneralIntegrationMapping.{DELETE_ENUM}.toString(),
            LiqAPIDelete{BusinessObject}Integration.class);
        liqAPiDataDelete.get{Identifier}().setIdentifierValue(null); // field under test
        basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);

        assertEquals("false", basicExecuteDelete.getSuccess());
        basicExecuteDelete.getAPIMessages().forEach(message ->
            assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
        LOG.debug("In testDeleteWithout{Identifier}Value - END");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 2: Positive Tests (Successful Deletion)
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testSuccessfulDeleteById() throws JsonProcessingException {
        LOG.debug("Test: Successful delete by ID - START");

        // STEP 1: CREATE
        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

        // STEP 2: QUERY
        liqAPiDataQuery = getMainObjectFromJsonQuery(
            GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
            LiqAPIQuery{BusinessObject}Integration.class);
        liqAPiDataQuery.get{Identifier}().setIdentifierValue(
            ((LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteOutput.getResult()).get{IdField}());
        basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

        // STEP 3: DELETE
        liqAPiDataDelete = getMainObjectFromJsonDelete(
            GeneralIntegrationMapping.{DELETE_ENUM}.toString(),
            LiqAPIDelete{BusinessObject}Integration.class);
        liqAPiDataDelete.get{Identifier}().setIdentifierType("id");
        liqAPiDataDelete.get{Identifier}().setIdentifierValue(
            ((LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteOutput.getResult()).get{IdField}());
        ((List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) basicExecuteQuery.getResult()).stream().forEach(p -> {
            try {
                String dateAsFormattedString = DateUtility.getDateAsFormattedString(
                    p.getUpdateTimeStamp(), "yyyy-MM-dd HH:mm:ss.S");
                liqAPiDataDelete.setMatchUpdatedTimestamp(dateAsFormattedString);
                basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });

        assertEquals("true", basicExecuteDelete.getSuccess());
        LOG.debug("Test: Successful delete by ID - END");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 3: If-Match / Concurrency Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testDeleteWithoutIfMatch() throws JsonProcessingException {
        // Full 3-step bootstrap...
        // After bootstrap: set null timestamp
        liqAPiDataDelete.setMatchUpdatedTimestamp(null);
        basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
        assertEquals("false", basicExecuteDelete.getSuccess());
    }

    @Test
    public void testDeleteWithStaleIfMatch() throws JsonProcessingException {
        // Full 3-step bootstrap...
        // After bootstrap: set stale timestamp
        liqAPiDataDelete.setMatchUpdatedTimestamp("1900-01-01 00:00:00.0");
        basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
        assertEquals("false", basicExecuteDelete.getSuccess());
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 4: Post-Delete Verification Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testDeleted{BusinessObject}IsNotQueryable() throws JsonProcessingException {
        // Full 3-step bootstrap with successful delete...
        // After successful delete, re-query:
        liqAPiDataQuery.get{Identifier}().setIdentifierValue(deletedId);
        LiqAPIResponse requery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
        assertEquals("false", requery.getSuccess());
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 5: Class-Mapping Coverage Tests
    // ═══════════════════════════════════════════════════════════════

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
}
```

---

## Variant B: `callBasicExecute` Pattern (Outstanding Transactions)

**Used by**: LoanDrawdown, LoanPrincipalPayment

These use direct `basicValidate()` / `basicExecute()` calls and `LiqAPIOutstandingTransactionIdentifier`.

```java
package com.misys.liq.api.rest.executable.outstanding.{subdomain};

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.data.outstanding.LiqAPIOutstandingTransactionIdentifier;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import java.util.List;
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
public class LiqAPIDelete{BusinessObject}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPIDelete{BusinessObject}IntegrationTest.class);

    private LiqAPICreate{BusinessObject}Integration liqAPIDataCreate;
    private LiqAPIQuery{BusinessObject}Integration  liqAPIDataQuery;
    private LiqAPIDelete{BusinessObject}Integration liqAPIDataDelete;
    private LiqAPI{BusinessObject}IntegrationAsReturnValue outputCreate;
    private List<LiqAPI{BusinessObject}IntegrationAsReturnValue> queryOutput;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
        LoanIQ.currentSession().setIntegrationAPIMode(Boolean.TRUE);
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 1: Mandatory Validation Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(1)
    public void testDeleteWithoutTransactionIdentifier() throws JsonProcessingException {
        LOG.debug("In testDeleteWithoutTransactionIdentifier - START");

        // STEP 1: CREATE
        liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataCreate.basicValidate();
        outputCreate = (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIDataCreate.basicExecute();
        Assertions.assertNotNull(outputCreate.getLoanTransactionId());

        // STEP 2: QUERY
        liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
            LiqAPIQuery{BusinessObject}Integration.class);
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
        queryOutput = (List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
        Assertions.assertFalse(queryOutput.isEmpty());

        // STEP 3: DELETE — null identifier
        liqAPIDataDelete = new LiqAPIDelete{BusinessObject}Integration();
        liqAPIDataDelete.setOutstandingTransactionIdentifier(null);

        Assertions.assertThrows(Exception.class, () -> {
            LiqApiDataUtil.callBasicValidate(liqAPIDataDelete);
        });

        LOG.debug("In testDeleteWithoutTransactionIdentifier - END");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 2: Positive Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(2)
    public void testSuccessfulDeleteByTransactionId() throws JsonProcessingException {
        LOG.debug("In testSuccessfulDeleteByTransactionId - START");

        // STEP 1: CREATE
        liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataCreate.basicValidate();
        outputCreate = (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIDataCreate.basicExecute();
        Assertions.assertNotNull(outputCreate.getLoanTransactionId());

        // STEP 2: QUERY
        liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
            LiqAPIQuery{BusinessObject}Integration.class);
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
        queryOutput = (List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
        Assertions.assertFalse(queryOutput.isEmpty());

        // STEP 3: DELETE
        liqAPIDataDelete = new LiqAPIDelete{BusinessObject}Integration();
        liqAPIDataDelete.setOutstandingTransactionIdentifier(new LiqAPIOutstandingTransactionIdentifier());
        liqAPIDataDelete.getOutstandingTransactionIdentifier().setIdentifierType(
            LiqAPIOutstandingTransactionIdentifier.OutstandingTransactionIdentifierType.transactionId.name());
        liqAPIDataDelete.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());

        LiqApiDataUtil.callBasicValidate(liqAPIDataDelete);
        Object deleteResult = LiqApiDataUtil.callBasicExecute(liqAPIDataDelete);
        Assertions.assertNotNull(deleteResult);

        LOG.debug("In testSuccessfulDeleteByTransactionId - END");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 3: Post-Delete Verification
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(3)
    public void testDeleted{BusinessObject}IsNotQueryable() throws JsonProcessingException {
        // Full 3-step bootstrap with successful delete...
        // Re-query after delete
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
        Assertions.assertThrows(Exception.class, () -> {
            LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
        });
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 4: Class-Mapping Coverage
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testNonPrimitiveFieldMappings() {
        assertNotNull(LiqAPIDelete{BusinessObject}Integration.clazz.nonPrimitiveFieldMappings());
    }

    @Test
    public void testPrimitiveFieldMappings() {
        assertNotNull(LiqAPIDelete{BusinessObject}Integration.clazz.primitiveFieldMappings());
    }

    @Test
    public void testSecurityAccessSymbol() {
        assertEquals("Delete{BusinessObject}Integration",
            LiqAPIDelete{BusinessObject}Integration.clazz.securityAccessSymbol());
    }
}
```

---

## Variant C: Cancel-as-Delete Pattern

**Used by**: LoanRepricing (`LiqAPICancelLoanRepricing`), LoanInterestPayment (`LiqAPICancelInterestPayment`)

These use `basicNew()` to instantiate the cancel DTO and wire a `LiqAPIOutstandingTransactionIdentifier`.

```java
package com.misys.liq.api.executable.{subdomain};

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.data.outstanding.LiqAPIOutstandingTransactionIdentifier;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import java.util.List;
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
public class LiqAPICancel{BusinessObject}IntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPICancel{BusinessObject}IntegrationTest.class);

    private LiqAPICreate{BusinessObject}Integration liqAPIDataCreate;
    private LiqAPICancel{BusinessObject} liqAPIDataCancel;
    private LiqAPI{BusinessObject}IntegrationAsReturnValue outputCreate;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
        LoanIQ.currentSession().setIntegrationAPIMode(Boolean.TRUE);
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 1: Mandatory Validation Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(1)
    public void testCancelWithoutTransactionIdentifier() throws JsonProcessingException {
        LOG.debug("In testCancelWithoutTransactionIdentifier - START");

        // STEP 1: CREATE
        liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataCreate.basicValidate();
        outputCreate = (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIDataCreate.basicExecute();
        Assertions.assertNotNull(outputCreate.getTransactionId());

        // STEP 2: QUERY
        LiqAPIQuery{BusinessObject}Integration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
            LiqAPIQuery{BusinessObject}Integration.class);
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getTransactionId());
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
        List<LiqAPI{BusinessObject}IntegrationAsReturnValue> queryResults =
            (List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
        Assertions.assertFalse(queryResults.isEmpty());

        // STEP 3: CANCEL — null identifier
        liqAPIDataCancel = (LiqAPICancel{BusinessObject}) LiqAPICancel{BusinessObject}.clazz.basicNew();
        liqAPIDataCancel.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataCancel.setOutstandingTransactionIdentifier(null);

        Assertions.assertThrows(Exception.class, () -> {
            liqAPIDataCancel.basicValidate();
        });

        LOG.debug("In testCancelWithoutTransactionIdentifier - END");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 2: Positive Tests
    // ═══════════════════════════════════════════════════════════════

    @Test
    @Order(2)
    public void testCancelWithValidTransactionId() throws JsonProcessingException {
        LOG.debug("In testCancelWithValidTransactionId - START");

        // STEP 1: CREATE
        liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{CREATE_ENUM}.toString(),
            LiqAPICreate{BusinessObject}Integration.class);
        liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataCreate.basicValidate();
        outputCreate = (LiqAPI{BusinessObject}IntegrationAsReturnValue) liqAPIDataCreate.basicExecute();
        Assertions.assertNotNull(outputCreate.getTransactionId());

        // STEP 2: QUERY
        LiqAPIQuery{BusinessObject}Integration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.{QUERY_ENUM}.toString(),
            LiqAPIQuery{BusinessObject}Integration.class);
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getTransactionId());
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
        List<LiqAPI{BusinessObject}IntegrationAsReturnValue> queryResults =
            (List<LiqAPI{BusinessObject}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
        Assertions.assertFalse(queryResults.isEmpty());

        // STEP 3: CANCEL
        liqAPIDataCancel = (LiqAPICancel{BusinessObject}) LiqAPICancel{BusinessObject}.clazz.basicNew();
        liqAPIDataCancel.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        LiqAPIOutstandingTransactionIdentifier identifier = new LiqAPIOutstandingTransactionIdentifier();
        identifier.setIdentifierType(
            LiqAPIOutstandingTransactionIdentifier.OutstandingTransactionIdentifierType.transactionId.name());
        identifier.setIdentifierValue(outputCreate.getTransactionId());
        liqAPIDataCancel.setOutstandingTransactionIdentifier(identifier);

        liqAPIDataCancel.basicValidate();
        Object cancelResult = liqAPIDataCancel.basicExecute();
        Assertions.assertNotNull(cancelResult);

        LOG.debug("In testCancelWithValidTransactionId - END");
    }

    // ═══════════════════════════════════════════════════════════════
    // SECTION 3: Class-Mapping Coverage
    // ═══════════════════════════════════════════════════════════════

    @Test
    public void testSecurityFunctionParent() {
        assertEquals("loan", LiqAPICancel{BusinessObject}.clazz.securityFunctionParent());
    }

    @Test
    public void testTransactionClass() {
        LiqAPICancel{BusinessObject} cancel = (LiqAPICancel{BusinessObject}) LiqAPICancel{BusinessObject}.clazz.basicNew();
        assertNotNull(cancel.transactionClass());
    }

    @Test
    public void testGetStClass() {
        LiqAPICancel{BusinessObject} cancel = (LiqAPICancel{BusinessObject}) LiqAPICancel{BusinessObject}.clazz.basicNew();
        assertNotNull(cancel.getStClass());
    }

    @Test
    public void testGetJavaClass() {
        assertEquals(LiqAPICancel{BusinessObject}.class, LiqAPICancel{BusinessObject}.clazz.getJavaClass());
    }

    @Test
    public void testGetStSuperclass() {
        assertNotNull(LiqAPICancel{BusinessObject}.clazz.getStSuperclass());
    }

    @Test
    public void testBasicNew() {
        assertNotNull(LiqAPICancel{BusinessObject}.clazz.basicNew());
    }
}
```

---

## Variant D: Owner Identifier Pattern (with Product Identifier List)

**Used by**: ProductGuarantee, MISCode

These use an `LiqAPIOwnerIdentifier` to identify the parent entity and a list of item identifiers for deletion.

```java
package com.misys.liq.api.rest.executable.{domain};

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import com.misys.liq.api.rest.util.LiqApiDataUtil;
import com.misys.liq.utilities.DateUtility;
import java.util.Date;
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

    private LiqAPIUpdate{BusinessObject}Integration liqAPIData; // or LiqAPICreate...
    private LiqAPIDelete{BusinessObject}Integration liqAPiDataDelete;
    private LiqAPIResponse basicExecuteOutput;
    private LiqAPIResponse basicExecuteDelete;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
        LoanIQ.currentSession().setIntegrationAPIMode(Boolean.TRUE);
    }

    @Test
    @Order(1)
    public void testDeleteWithInvalidOwnerType() throws JsonProcessingException {
        // STEP 1: CREATE (Add entity)
        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.{ADD_ENUM}.toString(),
            LiqAPIUpdate{BusinessObject}Integration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
        assertEquals("true", basicExecuteOutput.getSuccess());

        // STEP 2: QUERY (extract from CREATE response)
        LiqAPI{BusinessObject}IntegrationAsReturnValue createResult =
            (LiqAPI{BusinessObject}IntegrationAsReturnValue) basicExecuteOutput.getResult();
        String entityId = createResult.get{IdList}().get(0).getIdentifierValue();
        Date updateTimeStamp = createResult.get{IdList}().get(0).getUpdateTimeStamp();

        // STEP 3: DELETE — mutate owner type
        liqAPiDataDelete = getMainObjectFromJsonDelete(
            GeneralIntegrationMapping.{DELETE_ENUM}.toString(),
            LiqAPIDelete{BusinessObject}Integration.class);
        liqAPiDataDelete.getOwnerIdentifier().setOwnerType("INVALID"); // field under test
        liqAPiDataDelete.get{IdentifierList}().get(0).setIdentifierType("id");
        liqAPiDataDelete.get{IdentifierList}().get(0).setIdentifierValue(entityId);
        String dateAsFormattedString = DateUtility.getDateAsFormattedString(
            updateTimeStamp, "yyyy-MM-dd HH:mm:ss.S");
        liqAPiDataDelete.setMatchUpdatedTimestamp(dateAsFormattedString);

        basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
        assertEquals("false", basicExecuteDelete.getSuccess());
    }
}
```

---

## Section Selection Guide

| Business Object Pattern | Variant | Identifier | If-Match Required |
|---|---|---|---|
| Deal, Facility | A | Domain-specific Identifier (`LiqAPIDealIdentifier`) | Yes |
| UpfrontFee | A | `LiqAPIUpfrontFeeIdentifier` | Yes |
| ProductGuarantee | D | `LiqAPIOwnerIdentifier` + `LiqAPIProductGuaranteeIdentifier` list | Yes |
| MISCode | D | `LiqAPIOwnerIdentifier` + misCodes list | No (varies) |
| LoanDrawdown | B | `LiqAPIOutstandingTransactionIdentifier` | No |
| LoanPrincipalPayment | B | `LiqAPIOutstandingTransactionIdentifier` | No |
| LoanRepricing | C | `LiqAPIOutstandingTransactionIdentifier` (Cancel) | No |
| LoanInterestPayment | C | `LiqAPIOutstandingTransactionIdentifier` (Cancel) | No |
