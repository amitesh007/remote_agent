# LoanIQ Update Test — Complete Example Patterns

> This document consolidates all code patterns from the various Update-test skills (Deal, Facility, UpfrontFee, LoanDrawdown, LoanRepricing, LoanInterestPayment, LoanPrincipalPayment, MISCode, AdditionalFields, Primary, ProductGuarantee).

---

## Pattern 1: Standalone Entity with 3-Step Bootstrap (CREATE → QUERY → UPDATE)

### Pattern 1A: Using `invokeApiInterface()` — UpfrontFee / Deal / Facility style

```java
@Test
@Order(1)
public void testSuccessfulUpdate() throws JsonProcessingException {
    LOG.debug("Test: Successful update scenario - START");

    // STEP 1: CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_{ENTITY}_TRANSACTION.toString(),
        LiqAPICreate{Entity}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

    // STEP 2: QUERY
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_TRANSACTION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(
        ((LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteOutput.getResult()).getTransactionId());
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    // STEP 3: UPDATE
    liqAPiDataUpdate = getMainObjectFromJsonUpdate(
        GeneralIntegrationMapping.UPDATE_{ENTITY}_TRANSACTION_INTEGRATION.toString(),
        LiqAPIUpdate{Entity}Integration.class);
    liqAPiDataUpdate.get{Entity}Identifiers().get(0).setIdentifierValue(
        ((LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteOutput.getResult()).getTransactionId());

    // Set If-Match timestamp from query result
    ((List<LiqAPI{Entity}IntegrationAsReturnValue>) basicExecuteQuery.getResult()).stream().forEach(p -> {
        try {
            String dateAsFormattedString = DateUtility.getDateAsFormattedString(
                p.getUpdateTimeStamp(), "yyyy-MM-dd HH:mm:ss.S");
            liqAPiDataUpdate.setMatchUpdatedTimestamp(dateAsFormattedString);
            basicExecuteUpdate = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);
            assertEquals("true", basicExecuteUpdate.getSuccess());
        } catch (Exception e) {
            throw new RuntimeException("Failed to execute update", e);
        }
    });

    LOG.debug("Test: Successful update scenario - END");
}
```

### Pattern 1B: Using `LiqApiDataUtil.callBasicExecute()` — LoanDrawdown / LoanRepricing style

```java
@Test
@Order(1)
public void testUpdateValid() throws JsonProcessingException {
    LOG.debug("In testUpdateValid() - START");

    // STEP 1: CREATE
    liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_{ENTITY}_VALID.toString(),
        LiqAPICreate{Entity}Integration.class);
    int randomSixDigit = 100000 + (int) (Math.random() * 900000);
    liqAPIDataCreate.getOutstandingIdentifier().setIdentifierValue("BORROWER " + randomSixDigit);
    LiqApiDataUtil.callBasicValidate(liqAPIDataCreate);
    liqAPIDataCreate.setParents();
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    outputCreate = (LiqAPI{Entity}IntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqAPIDataCreate);

    // STEP 2: QUERY
    liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_{ENTITY}_VALID.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    queryOutput = (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);

    String timestampFromQuery = LiqApiDataUtil.getUpdatedTimestampFromQuery(queryOutput,
        LiqAPI{Entity}IntegrationAsReturnValue::getUpdateTimeStamp);

    // STEP 3: UPDATE
    liqAPIDataUpdate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.UPDATE_{ENTITY}_VALID.toString(),
        LiqAPIUpdate{Entity}Integration.class);
    liqAPIDataUpdate.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    liqAPIDataUpdate.setParents();
    liqAPIDataUpdate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);

    // Execute update
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();

    Assertions.assertNotNull(outputUpdate);
    Assertions.assertNotNull(outputUpdate.getLoanTransactionId());
    Assertions.assertNotNull(outputUpdate.getUpdateTimeStamp());

    LOG.debug("testUpdateValid - ENDS");
}
```

### Pattern 1C: Using `basicValidate()` + `basicExecute()` directly — LoanInterestPayment / LoanPrincipalPayment style

```java
@Test
@Order(1)
public void testUpdatePaymentValid() throws JsonProcessingException {
    LOG.debug("In testUpdatePaymentValid() - START");

    // STEP 1: CREATE
    liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPICreate{Entity}Integration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIDataCreate.basicValidate();
    List<LiqAPI{Entity}IntegrationAsReturnValue> createResults =
        (List<LiqAPI{Entity}IntegrationAsReturnValue>) liqAPIDataCreate.basicExecute();
    Assertions.assertNotNull(createResults);
    Assertions.assertFalse(createResults.isEmpty());
    outputCreate = createResults.get(0);
    Assertions.assertNotNull(outputCreate.getLoanTransactionId());

    // STEP 2: QUERY (fetch live timestamp)
    liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    List<LiqAPI{Entity}IntegrationAsReturnValue> queryResults =
        (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    Assertions.assertFalse(queryResults.isEmpty());
    String timestampFromQuery = queryResults.get(0).getUpdateTimeStamp().toString();

    // STEP 3: UPDATE
    liqAPIDataUpdate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.UPDATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPIUpdate{Entity}Integration.class);
    liqAPIDataUpdate.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();

    Assertions.assertNotNull(outputUpdate);
    Assertions.assertNotNull(outputUpdate.getLoanTransactionId());
    Assertions.assertNotNull(outputUpdate.getUpdateTimeStamp());

    LOG.debug("testUpdatePaymentValid - ENDS");
}
```

### Pattern 1D: Using domain object for timestamp — LoanPrincipalPayment style

```java
@Test
@Order(1)
public void testUpdatePrincipalPaymentValid() throws JsonProcessingException {
    LOG.debug("In testUpdatePrincipalPaymentValid() - START");

    // STEP 1: CREATE
    liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPICreateLoanPrincipalPaymentIntegration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIDataCreate.basicValidate();
    outputCreate = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) liqAPIDataCreate.basicExecute();
    Assertions.assertNotNull(outputCreate.getLoanTransactionId());

    // STEP 2: QUERY (fetch live timestamp from domain object)
    LoanPrincipalPayment outstandingTran = (LoanPrincipalPayment)
        LoanPrincipalPayment.clazz.getForId(outputCreate.getLoanTransactionId());
    String timestampFromQuery = ((LS2UpdateableData) outstandingTran).getUpdateTimeStamp().toString();

    // STEP 3: UPDATE
    liqAPIDataUpdate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.UPDATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPIUpdateLoanPrincipalPaymentIntegration.class);
    liqAPIDataUpdate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIDataUpdate.loanTransactionId = outputCreate.getLoanTransactionId();
    liqAPIDataUpdate.outstandingTran = outstandingTran;
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);

    // Execute
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();
    Assertions.assertNotNull(outputUpdate.getLoanTransactionId());

    LOG.debug("testUpdatePrincipalPaymentValid - ENDS");
}
```

### Pattern 1E: Using domain object directly — Primary/Circle style

```java
@Test
@Order(1)
public void testUpdatePrimaryValid() throws JsonProcessingException {
    LOG.debug("In testUpdatePrimaryValid() - START");

    // STEP 1: CREATE
    liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRIMARY_CIRCLE_INTEGRATION.toString(),
        LiqAPICreatePrimaryIntegration.class);
    liqApiDataCreate.getFacilityDetails().stream().forEach(
        facilityDetail -> facilityDetail.setPortfolioAllocation(null));
    LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
    liqApiDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutputCreate = (LiqAPICircleIntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqApiDataCreate);
    assertNotNull(basicExecuteOutputCreate.getCircleId());

    // STEP 2: QUERY (load domain object for timestamp)
    OriginationDealPrimary primary = (OriginationDealPrimary) OriginationDealPrimary.clazz
        .getForId(basicExecuteOutputCreate.getCircleId());
    assertNotNull(primary);

    // STEP 3: UPDATE
    liqApiDataUpdate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.UPDATE_PRIMARY_CIRCLE_INTEGRATION.toString(),
        LiqAPIUpdatePrimaryIntegration.class);
    liqApiDataUpdate.getCircleIdentifier().setIdentifierValue(basicExecuteOutputCreate.getCircleId());
    liqApiDataUpdate.setMatchUpdatedTimestamp(primary.getUpdateTimeStamp().toString());

    // Execute
    LiqApiDataUtil.callBasicValidate(liqApiDataUpdate);
    LiqAPICircleIntegrationAsReturnValue outputUpdate =
        (LiqAPICircleIntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqApiDataUpdate);
    assertNotNull(outputUpdate.getCircleId());

    LOG.debug("testUpdatePrimaryValid - ENDS");
}
```

---

## Pattern 2: Owner-Based Entity with 2-Step Bootstrap (QUERY → UPDATE)

### Pattern 2A: MISCode style — Owner-based with forEach timestamp binding

```java
@Test
@Order(1)
public void testUpdateMISCodeSuccess() throws JsonProcessingException {
    LOG.debug("In testUpdateMISCodeSuccess() - START");

    // STEP 1: CREATE (ensure deal with MIS codes exists)
    LiqAPICreateDealIntegration liqAPIDataCreate = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_WITH_MISCODE.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPIResponse basicExecuteCreate = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataCreate);
    assertEquals("true", basicExecuteCreate.getSuccess());

    // STEP 2: QUERY (fetch timestamp)
    liqAPIDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_MISCODE_INTEGRATION_DEAL.toString(),
        LiqAPIQueryMISCodeIntegration.class);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataQuery);

    // STEP 3: UPDATE
    liqAPiDataUpdate = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.UPDATE_MISCODE_INTEGRATION_DEAL.toString(),
        LiqAPIUpdateMISCodeIntegration.class);
    ((List<LiqAPIMISCodeIntegrationAsReturnValue>) basicExecuteQuery.getResult()).forEach(p -> {
        try {
            String dateAsFormattedString = DateUtility.getDateAsFormattedString(
                p.getUpdateTimeStamp(), "yyyy-MM-dd HH:mm:ss.S");
            liqAPiDataUpdate.setMatchUpdatedTimestamp(dateAsFormattedString);
            basicExecuteUpdate = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);
            assertEquals("true", basicExecuteUpdate.getSuccess());
        } catch (Exception e) {
            LOG.error("Exception: {}", e.getMessage());
        }
    });

    LOG.debug("testUpdateMISCodeSuccess - ENDS");
}
```

### Pattern 2B: AdditionalFields style — Owner-based direct update

```java
@Test
@Order(1)
public void testSuccessfulUpdateWithDealOwner() throws JsonProcessingException {
    LOG.debug("In testSuccessfulUpdateWithDealOwner - START");

    // STEP 1: QUERY (verify current state)
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_DEAL_ADDITIONAL_FIELDS_SUCCESS.toString(),
        LiqAPIQueryAdditionalFieldsIntegration.class);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    // STEP 2: UPDATE
    liqAPiDataUpdate = getMainObjectFromJsonUpdate(
        GeneralIntegrationMapping.UPDATE_ADDITIONAL_FIELDS_SUCCESS.toString(),
        LiqAPIUpdateAdditionalFieldsIntegration.class);
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);
    assertEquals("true", basicExecuteOutput.getSuccess());

    LOG.debug("In testSuccessfulUpdateWithDealOwner - END");
}
```

---

## Pattern 3: Negative Test — Missing Required Field

### Pattern 3A: Using `invokeApiInterface()` assertion pattern

```java
@Test
@Order(2)
public void testUpdateWithoutRequiredField() throws JsonProcessingException {
    LOG.debug("In testUpdateWithoutRequiredField - START");

    // STEP 1: CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_{ENTITY}_TRANSACTION.toString(),
        LiqAPICreate{Entity}Integration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

    // STEP 2: QUERY
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_TRANSACTION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(
        ((LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteOutput.getResult()).getTransactionId());
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    // STEP 3: UPDATE — mutate the field under test then invoke
    liqAPiDataUpdate = getMainObjectFromJsonUpdate(
        GeneralIntegrationMapping.UPDATE_{ENTITY}_TRANSACTION_INTEGRATION.toString(),
        LiqAPIUpdate{Entity}Integration.class);
    liqAPiDataUpdate.get{Entity}Identifiers().get(0).setIdentifierValue(
        ((LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteOutput.getResult()).getTransactionId());
    liqAPiDataUpdate.set{Field}(null); // field under test: null value
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);

    // Assert failure
    assertNotNull(basicExecuteOutput, "Response should not be null");
    assertEquals("false", basicExecuteOutput.getSuccess(), "Execution should fail");
    basicExecuteOutput.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));

    LOG.debug("In testUpdateWithoutRequiredField - END");
}
```

### Pattern 3B: Using exception assertion pattern

```java
@Test
@Order(2)
public void testUpdateWithoutTransactionIdentifier() throws JsonProcessingException {
    LOG.debug("In testUpdateWithoutTransactionIdentifier() - START");

    // Full bootstrap...
    // (CREATE and QUERY steps as above)

    // STEP 3: UPDATE — set identifier to null
    liqAPIDataUpdate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.UPDATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPIUpdate{Entity}Integration.class);
    liqAPIDataUpdate.setOutstandingTransactionIdentifier(null);

    // Assert exception thrown during validation
    Assertions.assertThrows(Exception.class, () -> {
        liqAPIDataUpdate.basicValidate();
    });

    LOG.debug("testUpdateWithoutTransactionIdentifier - ENDS");
}
```

---

## Pattern 4: Invalid Code Table Value

```java
@Test
@Order(3)
public void testUpdateWithInvalidCodeTableValue() throws JsonProcessingException {
    LOG.debug("In testUpdateWithInvalidCodeTableValue - START");

    // Full 3-step bootstrap...

    // After bootstrap, mutate the code table field
    liqAPiDataUpdate.set{CodeTableField}("INVALID");

    // Set If-Match timestamp
    ((List<LiqAPI{Entity}IntegrationAsReturnValue>) basicExecuteQuery.getResult()).stream().forEach(p -> {
        try {
            String dateAsFormattedString = DateUtility.getDateAsFormattedString(
                p.getUpdateTimeStamp(), "yyyy-MM-dd HH:mm:ss.S");
            liqAPiDataUpdate.setMatchUpdatedTimestamp(dateAsFormattedString);
            basicExecuteUpdate = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);
            assertEquals("false", basicExecuteUpdate.getSuccess());
            boolean foundError = false;
            for (Object message : basicExecuteUpdate.getAPIMessages()) {
                String errorMsg = ((LiqAPIExceptionMessage) message).getMessage();
                if (errorMsg.contains("INVALID") && errorMsg.contains("is not a code in table")) {
                    foundError = true;
                    break;
                }
            }
            assertTrue(foundError, "Should report invalid code table value");
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    });

    LOG.debug("In testUpdateWithInvalidCodeTableValue - END");
}
```

---

## Pattern 5: If-Match Timestamp Validation

### Pattern 5A: Missing If-Match

```java
@Test
@Order(4)
public void testUpdateWithoutIfMatch() throws JsonProcessingException {
    LOG.debug("In testUpdateWithoutIfMatch - START");

    // Full 3-step bootstrap...

    // After bootstrap, do NOT set matchUpdatedTimestamp
    liqAPiDataUpdate.setMatchUpdatedTimestamp(null);
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);

    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));

    LOG.debug("In testUpdateWithoutIfMatch - END");
}
```

### Pattern 5B: Stale If-Match

```java
@Test
@Order(5)
public void testUpdateWithStaleIfMatch() throws JsonProcessingException {
    LOG.debug("In testUpdateWithStaleIfMatch - START");

    // Full 3-step bootstrap...

    // After bootstrap, set stale timestamp
    liqAPiDataUpdate.setMatchUpdatedTimestamp("1900-01-01 00:00:00.0");
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);

    assertEquals("false", basicExecuteOutput.getSuccess());

    LOG.debug("In testUpdateWithStaleIfMatch - END");
}
```

---

## Pattern 6: Collection Field Tests

### Pattern 6A: Add valid item to collection

```java
@Test
@Order(10)
public void testUpdateWithValidCollectionItem() throws JsonProcessingException {
    // Full bootstrap...

    // After bootstrap, add valid item to collection
    List<LiqAPI{CollectionItem}> items = new ArrayList<>();
    LiqAPI{CollectionItem} item = new LiqAPI{CollectionItem}();
    item.set{Field1}("VALID_VALUE");
    item.set{Field2}(BigDecimal.valueOf(100.00));
    items.add(item);
    liqAPiDataUpdate.set{CollectionField}(items);

    // Set timestamp and execute
    // ... (timestamp binding from query)
    basicExecuteUpdate = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);
    assertEquals("true", basicExecuteUpdate.getSuccess());
}
```

### Pattern 6B: Duplicate item in collection

```java
@Test
@Order(11)
public void testUpdateWithDuplicateCollectionItem() throws JsonProcessingException {
    // Full bootstrap...

    // After bootstrap, add duplicate items
    List<LiqAPI{CollectionItem}> items = new ArrayList<>();
    LiqAPI{CollectionItem} item1 = new LiqAPI{CollectionItem}();
    item1.set{PrimaryKey}("TYPE_A");
    LiqAPI{CollectionItem} item2 = new LiqAPI{CollectionItem}();
    item2.set{PrimaryKey}("TYPE_A"); // duplicate
    items.add(item1);
    items.add(item2);
    liqAPiDataUpdate.set{CollectionField}(items);

    // Set timestamp and execute
    // ... (timestamp binding from query)
    basicExecuteUpdate = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);
    assertEquals("false", basicExecuteUpdate.getSuccess());
}
```

---

## Pattern 7: Class-Mapping Coverage Tests

```java
@Test
public void testNonPrimitiveFieldMappings() {
    assertFalse(LiqAPIUpdate{Entity}Integration.clazz.nonPrimitiveFieldMappings().isEmpty());
}

@Test
public void testNonPrimitiveFieldCollectionMappings() {
    List mappings = LiqAPIUpdate{Entity}Integration.clazz.nonPrimitiveFieldCollectionMappings();
    assertNotNull(mappings);
}

@Test
public void testPrimitiveFieldMappings() {
    assertFalse(LiqAPIUpdate{Entity}Integration.clazz.primitiveFieldMappings().isEmpty());
}

@Test
public void testSecurityAccessSymbol() throws JsonProcessingException {
    LiqAPIUpdate{Entity}Integration data = getMainObjectFromJsonUpdate(
        GeneralIntegrationMapping.UPDATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPIUpdate{Entity}Integration.class);
    assertNotNull(data.securityAccessSymbol());
    assertEquals("Update{Entity}Integration", data.securityAccessSymbol());
}

@Test
public void testIsRest() {
    assertTrue(LiqAPIUpdate{Entity}Integration.clazz.isRest());
}

@Test
public void testBasicNew() {
    Object newInstance = LiqAPIUpdate{Entity}Integration.clazz.basicNew();
    assertNotNull(newInstance);
    assertTrue(newInstance instanceof LiqAPIUpdate{Entity}Integration);
}

@Test
public void testGetJavaClass() {
    assertEquals(LiqAPIUpdate{Entity}Integration.class,
        LiqAPIUpdate{Entity}Integration.clazz.getJavaClass());
}

@Test
public void testGetStSuperclass() {
    assertNotNull(LiqAPIUpdate{Entity}Integration.clazz.getStSuperclass());
}

@Test
public void testGetStClass() throws JsonProcessingException {
    LiqAPIUpdate{Entity}Integration data = getMainObjectFromJsonUpdate(
        GeneralIntegrationMapping.UPDATE_{ENTITY}_INTEGRATION.toString(),
        LiqAPIUpdate{Entity}Integration.class);
    assertNotNull(data.getStClass());
    assertEquals(LiqAPIUpdate{Entity}Integration.clazz, data.getStClass());
}
```

---

## Pattern 8: Getter/Setter Unit Tests (No DB)

```java
@Test
public void testFieldNameGetterSetter() {
    LiqAPIUpdate{Entity}Integration instance = new LiqAPIUpdate{Entity}Integration();
    instance.set{FieldName}("TEST_VALUE");
    assertEquals("TEST_VALUE", instance.get{FieldName}());
}

@Test
public void testFieldNameSetToNull() {
    LiqAPIUpdate{Entity}Integration instance = new LiqAPIUpdate{Entity}Integration();
    instance.set{FieldName}(null);
    assertNull(instance.get{FieldName}());
}

@Test
public void testCollectionFieldGetterSetter() {
    LiqAPIUpdate{Entity}Integration instance = new LiqAPIUpdate{Entity}Integration();
    List<{ElementType}> list = new ArrayList<>();
    {ElementType} item = new {ElementType}();
    list.add(item);
    instance.set{CollectionField}(list);
    assertEquals(1, instance.get{CollectionField}().size());
}
```

---

## Pattern 9: Non-Updatable Field Verification

```java
@Test
@Order(20)
public void testNonUpdatableFieldNotChanged() throws JsonProcessingException {
    // Full bootstrap...

    // Record original value
    String originalValue = queryOutput.get(0).get{NonUpdatableField}();

    // Attempt to update non-updatable field
    liqAPIDataUpdate.set{NonUpdatableField}("MODIFIED_VALUE");
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();

    // Re-query and verify unchanged
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    List<LiqAPI{Entity}IntegrationAsReturnValue> postUpdateResult =
        (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    assertEquals(originalValue, postUpdateResult.get(0).get{NonUpdatableField}(),
        "{NonUpdatableField} should not be updatable");
}
```

---

## Pattern 10: Post-Update Verification via Re-Query

```java
@Test
@Order(30)
public void testUpdateWithVerification() throws JsonProcessingException {
    // Full 3-step bootstrap...

    // Mutate and execute update
    liqAPIDataUpdate.set{Field}(newValue);
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();
    Assertions.assertNotNull(outputUpdate);

    // POST-UPDATE VERIFICATION
    LiqAPIQuery{Entity}Integration postUpdateQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_{ENTITY}_VALID.toString(),
        LiqAPIQuery{Entity}Integration.class);
    postUpdateQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    LiqApiDataUtil.callBasicValidate(postUpdateQuery);
    List<LiqAPI{Entity}IntegrationAsReturnValue> postUpdateOutput =
        (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(postUpdateQuery);
    Assertions.assertNotNull(postUpdateOutput);
    Assertions.assertFalse(postUpdateOutput.isEmpty());
    Assertions.assertEquals(newValue, postUpdateOutput.get(0).get{Field}());
}
```

---

## Pattern 11: ProductGuarantee Style (Create response provides timestamp)

```java
@Test
@Order(1)
public void testUpdateProductGuaranteeSuccess() throws JsonProcessingException {
    LOG.debug("In testUpdateProductGuaranteeSuccess - START");

    // STEP 1: CREATE (Add Guarantee)
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.ADD_GUARANTEE_FOR_FACILITY.toString(),
        LiqAPIUpdateProductGuaranteeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());

    // STEP 2: Extract identifier and timestamp from CREATE response
    LiqAPIProductGuaranteeIntegrationAsReturnValue createResult =
        (LiqAPIProductGuaranteeIntegrationAsReturnValue) basicExecuteOutput.getResult();
    String guaranteeId = createResult.getProductGuaranteeIdentifierList().get(0).getIdentifierValue();
    Date updateTimeStamp = createResult.getProductGuaranteeIdentifierList().get(0).getUpdateTimeStamp();

    // STEP 3: UPDATE
    liqAPiDataUpdate = getMainObjectFromJsonUpdate(
        GeneralIntegrationMapping.ADD_GUARANTEE_FOR_FACILITY.toString(),
        LiqAPIUpdateProductGuaranteeIntegration.class);
    liqAPiDataUpdate.getOwnerIdentifier().setOwnerIdentifierValue(
        createResult.getOwnerIdentifierValue());
    String dateAsFormattedString = DateUtility.getDateAsFormattedString(
        updateTimeStamp, "yyyy-MM-dd HH:mm:ss.S");
    liqAPiDataUpdate.setMatchUpdatedTimestamp(dateAsFormattedString);

    // Execute
    basicExecuteUpdate = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataUpdate);
    assertEquals("true", basicExecuteUpdate.getSuccess());

    LOG.debug("testUpdateProductGuaranteeSuccess - ENDS");
}
```

---

## Pattern 12: Boolean Field Update Tests

```java
@Test
@Order(15)
public void testUpdateBooleanFieldTrue() throws JsonProcessingException {
    // Full 3-step bootstrap...

    liqAPIDataUpdate.set{BooleanField}(Boolean.TRUE);
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();
    Assertions.assertNotNull(outputUpdate);
    Assertions.assertEquals(Boolean.TRUE, outputUpdate.get{BooleanField}());
}

@Test
@Order(16)
public void testUpdateBooleanFieldFalse() throws JsonProcessingException {
    // Full 3-step bootstrap...

    liqAPIDataUpdate.set{BooleanField}(Boolean.FALSE);
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();
    Assertions.assertNotNull(outputUpdate);
}
```

---

## Pattern 13: Date Field Validation Tests

```java
@Test
@Order(17)
public void testUpdateWithValidDate() throws JsonProcessingException {
    // Full 3-step bootstrap...

    liqAPIDataUpdate.set{DateField}(LiqDate.clazz.today());
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();
    Assertions.assertNotNull(outputUpdate);
}

@Test
@Order(18)
public void testUpdateWithInvalidDate() throws JsonProcessingException {
    // Full 3-step bootstrap...

    liqAPIDataUpdate.set{DateField}(DateUtility.createDate(1111, 1, 1)); // far past
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);

    Assertions.assertThrows(Exception.class, () -> {
        liqAPIDataUpdate.basicValidate();
        liqAPIDataUpdate.basicExecute();
    });
}
```

---

## Pattern 14: Amount/Numeric Field Validation Tests

```java
@Test
@Order(19)
public void testUpdateWithValidAmount() throws JsonProcessingException {
    // Full 3-step bootstrap...

    liqAPIDataUpdate.setRequestedAmount(BigDecimal.valueOf(5000.00));
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
    liqAPIDataUpdate.basicValidate();
    outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();
    Assertions.assertNotNull(outputUpdate);
}

@Test
@Order(20)
public void testUpdateWithNegativeAmount() throws JsonProcessingException {
    // Full 3-step bootstrap...

    liqAPIDataUpdate.setRequestedAmount(BigDecimal.valueOf(-100));
    liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);

    // May throw during validate or execute
    try {
        liqAPIDataUpdate.basicValidate();
        outputUpdate = (LiqAPI{Entity}IntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();
        fail("Expected exception for negative amount");
    } catch (Exception e) {
        assertTrue(e.getMessage().contains("amount") || e.getMessage().contains("Amount"));
    }
}
```
