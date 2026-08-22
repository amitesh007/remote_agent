# LoanIQ Query Test API — Code Pattern Examples

> This document consolidates all code patterns from the individual query-test skills (deal-get-test, facility-get-test, loandrawdown-get-test, loaninterestpayment-get-test, loanprincipalpayment-get-test, loanrepricing-get-test, primary-get-test, upfrontfee-get-test, miscode-get-test, additionalfields-get-test).

---

## Pattern 1: Standard Entity Query (Deal, Facility, UpfrontFee)

### Bootstrap: CREATE → QUERY via `invokeApiInterface()`

```java
// ── STEP 1: CREATE SEED ──────────────────────────────────────────────
liqAPIData = getMainObjectFromJsonCreate(
    GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
    LiqAPICreate{Entity}Integration.class);
liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

LiqAPI{Entity}IntegrationAsReturnValue created =
    (LiqAPI{Entity}IntegrationAsReturnValue) basicExecuteOutput.getResult();

// ── STEP 2: QUERY ─────────────────────────────────────────────────────
liqAPiDataQuery = getMainObjectFromJsonQuery(
    GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
    LiqAPIQuery{Entity}Integration.class);
liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(created.get{Entity}Id());
basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
```

### Canonical Positive Example (Deal)

```java
@Test
public void testSuccessfulQueryById() throws JsonProcessingException {
    // bootstrap CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_INTEGRATION_ALL_ATTRIBUTES_FOR_QUERY.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

    // query
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_DEAL_INTEGRATION.toString(),
        LiqAPIQueryDealIntegration.class);
    liqAPiDataQuery.getDealIdentifier().setIdentifierValue(
        ((LiqAPIDealIntegrationAsReturnValue) basicExecuteOutput.getResult()).getDealId());
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    assertEquals("true", basicExecuteQuery.getSuccess());
    List<LiqAPIDealIntegrationAsReturnValue> results =
        (List<LiqAPIDealIntegrationAsReturnValue>) basicExecuteQuery.getResult();
    assertNotNull(results);
    assertFalse(results.isEmpty());
    assertNotNull(results.get(0).getDealId());
}
```

### Canonical Positive Example (Facility — full 2-step bootstrap)

```java
@Test
public void testQueryFacilityById() throws JsonProcessingException {
    LOG.debug("Test: Query facility by ID - START");

    // STEP 1: CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_FACILITY_INTEGRATION_PRIMITIVE.toString(),
        LiqAPICreateFacilityIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    String facilityId = ((LiqAPIFacilityIntegrationAsReturnValue) basicExecuteOutput.getResult()).getId();

    // STEP 2: QUERY
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_FACILITY_INTEGRATION.toString(),
        LiqAPIQueryFacilityIntegration.class);
    liqAPiDataQuery.getFacilityIdentifier().setIdentifierValue(facilityId);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    assertEquals("true", basicExecuteQuery.getSuccess());
    LiqAPIFacilityIntegrationAsReturnValue r =
        (LiqAPIFacilityIntegrationAsReturnValue) basicExecuteQuery.getResult();
    assertNotNull(r);
    assertNotNull(r.getId());
    assertNotNull(r.getFacilityName());
    assertNotNull(r.getFacilityType());
    assertNotNull(r.getUpdateTimeStamp());
    LOG.debug("Test: Query facility by ID - END");
}
```

### Canonical Positive Example (UpfrontFee)

```java
@Test
@Order(11)
public void testSuccessfulQueryById() throws JsonProcessingException {
    // bootstrap CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_UPFRONTFEE_TRANSACTION_WITH_AMOUNT.toString(),
        LiqAPICreateUpfrontFeeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

    // query
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_UPFRONTFEE_TRANSACTION.toString(),
        LiqAPIQueryUpfrontFeeIntegration.class);
    liqAPiDataQuery.getUpforntFeeIdentifier().setIdentifierValue(
        ((LiqAPIUpfrontFeeIntegrationAsReturnValue) basicExecuteOutput.getResult()).getTransactionId());
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    assertEquals("true", basicExecuteQuery.getSuccess());
}
```

---

## Pattern 2: Transaction Query (LoanDrawdown, LoanInterestPayment, LoanPrincipalPayment, LoanRepricing)

### Bootstrap: CREATE → QUERY via `LiqApiDataUtil`

```java
// CREATE
LiqAPICreate{Entity}Integration createData = LiqApiDataUtil.getObjectFromJson(
    GeneralIntegrationMapping.CREATE_{ENTITY}_INTEGRATION.toString(),
    LiqAPICreate{Entity}Integration.class);
createData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
createData.basicValidate();
{ReturnType} createOutput = ({ReturnType}) createData.basicExecute();
String transactionId = createOutput.get{TransactionId}();

// QUERY
LiqAPIQuery{Entity}Integration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
    GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
    LiqAPIQuery{Entity}Integration.class);
liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(transactionId);
LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
List<LiqAPI{Entity}IntegrationAsReturnValue> output =
    (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
```

### Canonical Positive Example (LoanDrawdown)

```java
@SuppressWarnings("unchecked")
@Test
public void testQueryLoanDrawdownValid() throws JsonProcessingException {
    LOG.debug("In testQueryLoanDrawdownValid() - START");

    LiqAPIQueryLoanDrawdownIntegration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_LOAN_DRAWDOWN_VALID.toString(),
        LiqAPIQueryLoanDrawdownIntegration.class);
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);

    List<LiqAPILoanDrawdownIntegrationAsReturnValue> output =
        (List<LiqAPILoanDrawdownIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);

    Assertions.assertNotNull(output);
    Assertions.assertFalse(output.isEmpty());
    Assertions.assertNotNull(output.get(0).getOutstandingTransactionIdentifier());
    Assertions.assertEquals(
        output.get(0).getOutstandingTransactionIdentifier().getIdentifierValue(),
        liqAPIDataQuery.getOutstandingTransactionIdentifier().getIdentifierValue());

    Assertions.assertEquals(TestDataConstants.SECURITY_ACCESS_SYMBOL_QUERY_LOAN_DRAWDOWN,
        LiqAPIQueryLoanDrawdownIntegration.clazz.securityAccessSymbol());
    Assertions.assertEquals(TestDataConstants.SECURITY_ACCESS_SYMBOL_QUERY_LOAN_DRAWDOWN,
        liqAPIDataQuery.securityAccessSymbol());

    LOG.debug("testQueryLoanDrawdownValid - ENDS");
}
```

### Canonical Positive Example (LoanInterestPayment — CREATE then QUERY)

```java
@SuppressWarnings("unchecked")
@Test
public void testQueryInterestPaymentValid() throws JsonProcessingException {
    LOG.debug("In testQueryInterestPaymentValid() - START");

    // First create an interest payment to query
    LiqAPICreateLoanInterestPaymentIntegration createData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_INTEREST_PMT_INTEGRATION.toString(),
        LiqAPICreateLoanInterestPaymentIntegration.class);
    createData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    createData.basicValidate();
    List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> createResults =
        (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) createData.basicExecute();
    Assertions.assertNotNull(createResults);
    Assertions.assertFalse(createResults.isEmpty());
    String transactionId = createResults.get(0).getLoanTransactionId();
    Assertions.assertNotNull(transactionId);

    // Query the created transaction
    LiqAPIQueryLoanInterestPaymentIntegration liqAPIDataQuery =
        (LiqAPIQueryLoanInterestPaymentIntegration) LiqAPIQueryLoanInterestPaymentIntegration.clazz.basicNew();
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(transactionId);
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);

    List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> output =
        (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);

    Assertions.assertNotNull(output);
    Assertions.assertFalse(output.isEmpty());
    Assertions.assertNotNull(output.get(0).getLoanTransactionId());
    Assertions.assertEquals(transactionId, output.get(0).getLoanTransactionId());
    Assertions.assertNotNull(output.get(0).getUpdateTimeStamp());
    Assertions.assertNotNull(output.get(0).getEffectiveDate());
    Assertions.assertNotNull(output.get(0).getStatusCode());
    Assertions.assertNotNull(output.get(0).getRequestedAmount());

    LOG.debug("testQueryInterestPaymentValid - ENDS");
}
```

### Canonical Positive Example (LoanPrincipalPayment)

```java
@SuppressWarnings("unchecked")
@Test
public void testQueryPrincipalPaymentValid() throws JsonProcessingException {
    LOG.debug("In testQueryPrincipalPaymentValid() - START");

    // First create a principal payment to query
    LiqAPICreateLoanPrincipalPaymentIntegration createData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPICreateLoanPrincipalPaymentIntegration.class);
    createData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    createData.basicValidate();
    LiqAPILoanPrincipalPaymentIntegrationAsReturnValue createOutput =
        (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) createData.basicExecute();
    Assertions.assertNotNull(createOutput.getLoanTransactionId());

    // Query the created transaction
    LiqAPIQueryLoanPrincipalPaymentIntegration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPIQueryLoanPrincipalPaymentIntegration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(
        createOutput.getLoanTransactionId());
    liqAPIDataQuery.basicValidate();

    LiqAPILoanPrincipalPaymentIntegrationAsReturnValue output =
        (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) liqAPIDataQuery.basicExecute();

    Assertions.assertNotNull(output);
    Assertions.assertNotNull(output.getLoanTransactionId());
    Assertions.assertEquals(createOutput.getLoanTransactionId(), output.getLoanTransactionId());
    Assertions.assertNotNull(output.getUpdateTimeStamp());

    LOG.debug("testQueryPrincipalPaymentValid - ENDS");
}
```

### Canonical Positive Example (LoanRepricing)

```java
@SuppressWarnings("unchecked")
@Test
public void testQueryLoanRepricingValid() throws JsonProcessingException {
    LOG.debug("In testQueryLoanRepricingValid() - START");

    // First create a loan repricing to query
    LiqAPICreateLoanRepricingIntegration createData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_REPRICING_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPICreateLoanRepricingIntegration.class);
    createData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    createData.basicValidate();
    LiqAPILoanRepricingIntegrationAsReturnValue createOutput =
        (LiqAPILoanRepricingIntegrationAsReturnValue) createData.basicExecute();
    Assertions.assertNotNull(createOutput.getTransactionId());

    // Query the created transaction
    LiqAPIQueryLoanRepricingIntegration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_LOAN_REPRICING_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPIQueryLoanRepricingIntegration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(
        createOutput.getTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);

    List<LiqAPILoanRepricingIntegrationAsReturnValue> output =
        (List<LiqAPILoanRepricingIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);

    Assertions.assertNotNull(output);
    Assertions.assertFalse(output.isEmpty());
    Assertions.assertNotNull(output.getFirst().getTransactionId());
    Assertions.assertEquals(createOutput.getTransactionId(), output.getFirst().getTransactionId());
    Assertions.assertNotNull(output.getFirst().getUpdateTimeStamp());
    Assertions.assertNotNull(output.getFirst().getEffectiveDate());
    Assertions.assertNotNull(output.getFirst().getStatusCode());
    Assertions.assertNotNull(output.getFirst().getOutstandingTransactionIdentifier());

    LOG.debug("testQueryLoanRepricingValid - ENDS");
}
```

---

## Pattern 3: Polymorphic Owner Query (MISCode, AdditionalFields)

### Bootstrap: Optional CREATE → QUERY with OwnerIdentifier

```java
// QUERY with owner identifier
liqAPIDataQuery = getMainObjectFromJsonQuery(
    GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION_{OWNER}.toString(),
    LiqAPIQuery{Entity}Integration.class);
basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataQuery);
```

### Canonical Positive Example (MISCode — with Deal owner)

```java
@Test
@Order(1)
public void testQueryMISCodeByDealAliasValid() throws JsonProcessingException {
    LOG.debug("In testQueryMISCodeByDealAliasValid() - START");

    // First create a deal with MIS codes to ensure data exists
    liqAPIDataCreate = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_WITH_MISCODE.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteCreateOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataCreate);
    assertEquals("true", basicExecuteCreateOutput.getSuccess());

    // Query MIS codes for the deal
    liqAPIDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_MISCODE_INTEGRATION_DEAL.toString(),
        LiqAPIQueryMISCodeIntegration.class);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataQuery);

    // Verify response
    assertNotNull(basicExecuteQuery);
    assertNotNull(basicExecuteQuery.getResult());
    LiqAPIMISCodeIntegrationAsReturnValue result =
        (LiqAPIMISCodeIntegrationAsReturnValue) ((ArrayList) basicExecuteQuery.getResult()).get(0);
    assertNotNull(result.getMisCodes());
    assertNotNull(result.getUpdateTimeStamp());
    assertNotNull(result.getOwnerIdentifiers());

    LOG.debug("testQueryMISCodeByDealAliasValid - ENDS");
}
```

### Canonical Positive Example (Primary/Circle)

```java
@SuppressWarnings("unchecked")
@Test
public void testQueryCircle() throws JsonProcessingException {
    // First create a circle to ensure data exists
    LiqAPICreatePrimaryIntegration liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRIMARY_CIRCLE_INTEGRATION.toString(),
        LiqAPICreatePrimaryIntegration.class);
    liqApiDataCreate.getFacilityDetails().stream().forEach(
        facilityDetail -> facilityDetail.setPortfolioAllocation(null));
    LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
    liqApiDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPICircleIntegrationAsReturnValue createOutput =
        (LiqAPICircleIntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqApiDataCreate);

    // Now query the created circle
    LiqAPIQueryCircleIntegration liqApiData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_CIRCLE_INTEGRATION.toString(),
        LiqAPIQueryCircleIntegration.class);
    liqApiData.getCircleIdentifier().setIdentifierValue(createOutput.getCircleId());

    LiqApiDataUtil.callBasicValidate(liqApiData);
    List<LiqAPICircleIntegrationAsReturnValue> basicExecuteOutputs =
        (List<LiqAPICircleIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqApiData);

    Assertions.assertNotNull(basicExecuteOutputs);
    for (LiqAPICircleIntegrationAsReturnValue basicExecuteOutput : basicExecuteOutputs) {
        if (basicExecuteOutput.getDealIdentifiers() != null)
            Assertions.assertNotNull(basicExecuteOutput.getDealIdentifiers());
        if (basicExecuteOutput.getFacilityDetails() != null)
            Assertions.assertNotNull(basicExecuteOutput.getFacilityDetails());
        if (basicExecuteOutput.getLenderDetails() != null)
            Assertions.assertNotNull(basicExecuteOutput.getLenderDetails());
    }
}
```

### Canonical Positive Example (AdditionalFields — no CREATE prerequisite)

```java
@Test
@Order(2)
public void testExecute_Success() throws JsonProcessingException {
    LOG.debug("Test: Successful query for Deal additional fields - START");

    integration = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_DEAL_ADDITIONAL_FIELDS_SUCCESS.toString(),
        LiqAPIQueryAdditionalFieldsIntegration.class);
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(integration);

    assertNotNull(basicExecuteOutput, "Response should not be null");
    assertEquals("true", basicExecuteOutput.getSuccess(), "Execution should succeed");
    LOG.debug("Test: Successful query for Deal additional fields - END");
}
```

---

## Negative Test Patterns

### Pattern A: Null Identifier (Standard Entity)

```java
@Test
@Order(1)
public void testQueryWithInvalid{Entity}Id() throws JsonProcessingException {
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPiDataQuery.get{Entity}Identifier().setIdentifierValue(null);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    assertEquals("false", basicExecuteQuery.getSuccess());
    basicExecuteQuery.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
}
```

### Pattern B: Null Identifier (Transaction Entity)

```java
@SuppressWarnings("unchecked")
@Test
public void testQuery{Entity}WithNullIdentifier() throws JsonProcessingException {
    LOG.debug("In testQuery{Entity}WithNullIdentifier() - START");

    LiqAPIQuery{Entity}Integration liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPIData.setOutstandingTransactionIdentifier(null);

    try {
        LiqApiDataUtil.callBasicValidate(liqAPIData);
        LiqApiDataUtil.callBasicExecute(liqAPIData);
        Assertions.fail("Expected exception for null identifier");
    } catch (Exception e) {
        Assertions.assertNotNull(e.getMessage());
        LOG.debug("Expected error: {}", e.getMessage());
    }

    LOG.debug("testQuery{Entity}WithNullIdentifier - ENDS");
}
```

### Pattern C: Invalid ID (Transaction Entity)

```java
@SuppressWarnings("unchecked")
@Test
public void testQuery{Entity}WithInvalidId() throws JsonProcessingException {
    LOG.debug("In testQuery{Entity}WithInvalidId() - START");

    LiqAPIQuery{Entity}Integration liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPIData.getOutstandingTransactionIdentifier().setIdentifierValue(TestDataConstants.INVALID_ID);

    try {
        LiqApiDataUtil.callBasicValidate(liqAPIData);
        List<LiqAPI{Entity}IntegrationAsReturnValue> output =
            (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIData);
    } catch (Exception e) {
        Assertions.assertEquals(
            StringUtility.bindWith(ErrorMessageConstants.INVALID_{ENTITY}_ERROR_MESSAGE,
                liqAPIData.getOutstandingTransactionIdentifier().getIdentifierType(),
                liqAPIData.getOutstandingTransactionIdentifier().getIdentifierValue()),
            e.getMessage());
    }

    LOG.debug("testQuery{Entity}WithInvalidId - ENDS");
}
```

### Pattern D: Null Owner Identifier (Polymorphic)

```java
@Test
@Order(2)
public void testQuery{Entity}WithoutOwnerIdentifier() throws JsonProcessingException {
    LOG.debug("In testQuery{Entity}WithoutOwnerIdentifier() - START");

    liqAPIDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPIDataQuery.setOwnerIdentifier(null);

    Exception exception = assertThrows(Exception.class, () -> liqAPIDataQuery.basicValidate());
    if (exception.getMessage() != null) {
        assertTrue(exception.getMessage().contains("Identifier is required"));
    }

    LOG.debug("testQuery{Entity}WithoutOwnerIdentifier - ENDS");
}
```

### Pattern E: Invalid Identifier Type (Polymorphic)

```java
@Test
public void testQuery{Entity}WithInvalidIdentifierType() throws JsonProcessingException {
    LiqAPIQuery{Entity}Integration liqApiData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqApiData.get{Entity}Identifier().setIdentifierType("ids");
    try {
        LiqApiDataUtil.callBasicValidate(liqApiData);
    } catch (Exception e) {
        Assertions.assertEquals(
            StringUtility.bindWith(ErrorMessageConstants.INVALID_{ENTITY}_IDENTIFIER_TYPE, "ids"),
            e.getMessage());
    }
}
```

---

## Class-Mapping Coverage Patterns

### Standard Pattern (all entities)

```java
@Test public void testNonPrimitiveFieldMappings() {
    assertNotNull(LiqAPIQuery{Entity}Integration.clazz.nonPrimitiveFieldMappings());
}
@Test public void testPrimitiveFieldMappings() {
    assertNotNull(LiqAPIQuery{Entity}Integration.clazz.primitiveFieldMappings());
}
@Test public void testSecurityAccessSymbol() {
    assertEquals("Query{Entity}Integration",
        LiqAPIQuery{Entity}Integration.clazz.securityAccessSymbol());
}
@Test public void testIsRest() {
    assertTrue(LiqAPIQuery{Entity}Integration.clazz.isRest());
}
@Test public void testBasicNew() {
    assertNotNull(LiqAPIQuery{Entity}Integration.clazz.basicNew());
}
@Test public void testGetStClass() {
    LiqAPIQuery{Entity}Integration data =
        (LiqAPIQuery{Entity}Integration) LiqAPIQuery{Entity}Integration.clazz.basicNew();
    assertNotNull(data.getStClass());
}
```

### Extended Pattern (for transaction entities)

```java
@Test public void testReturnType() {
    assertNotNull(LiqAPIQuery{Entity}Integration.clazz.getReturnType());
}
@Test public void testDocumentedReturnValues() {
    assertNotNull(LiqAPIQuery{Entity}Integration.clazz.documentedReturnValues());
}
@Test public void testSecurityFunctionParent() {
    assertNotNull(LiqAPIQuery{Entity}Integration.clazz.securityFunctionParent());
}
@Test public void testSupportsAdditionalFields() {
    assertFalse(LiqAPIQuery{Entity}Integration.clazz.supportsAdditionalFields());
}
@Test public void testResponseClassMappings() {
    assertNotNull(LiqAPI{Entity}IntegrationAsReturnValue.clazz.primitiveFieldMappings());
    assertNotNull(LiqAPI{Entity}IntegrationAsReturnValue.clazz.nonPrimitiveFieldMappings());
    assertNotNull(LiqAPI{Entity}IntegrationAsReturnValue.clazz.nonPrimitiveFieldCollectionMappings());
    assertTrue(LiqAPI{Entity}IntegrationAsReturnValue.clazz.isRest());
}
```

---

## Response Attribute Assertion Patterns

### Primitive Fields

```java
// Mandatory primitive — must not be null
assertNotNull(output.get{FieldName}(), "{FieldName} should not be null");

// Optional primitive — verify accessible
output.get{FieldName}(); // no assertion needed, just verify no exception

// Value equality (when seed data available)
assertEquals(expectedValue, output.get{FieldName}(),
    "{FieldName} should match expected value");
```

### Non-Primitive Single Fields

```java
// Verify nested object accessible
assertNotNull(output.get{NestedObject}(), "{NestedObject} should not be null");

// Verify sub-fields
assertNotNull(output.get{NestedObject}().get{SubField}());
```

### Non-Primitive Collection Fields

```java
// Verify collection exists and has items
assertNotNull(output.get{CollectionName}(), "{CollectionName} should not be null");
assertFalse(output.get{CollectionName}().isEmpty(),
    "{CollectionName} should not be empty");

// Verify elements have expected fields
output.get{CollectionName}().forEach(item -> {
    assertNotNull(item.get{SubField}());
});
```

---

## Spread/Composite Key Query Pattern (LoanDrawdown, LoanRepricing)

```java
@Test
public void testQuery{Entity}SpreadRateCompositeKey() throws JsonProcessingException {
    LOG.debug("In testQuery{Entity}SpreadRateCompositeKey() - START");

    LiqAPIQuery{Entity}Integration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_{ENTITY}_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPIQuery{Entity}Integration.class);
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);

    List<LiqAPI{Entity}IntegrationAsReturnValue> output =
        (List<LiqAPI{Entity}IntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);

    Assertions.assertNotNull(output);
    Assertions.assertFalse(output.isEmpty());
    // Verify composite key spread components
    if (output.getFirst().getOstSpreadAdjustmentComponents() != null) {
        assertFalse(output.getFirst().getOstSpreadAdjustmentComponents().isEmpty());
        output.getFirst().getOstSpreadAdjustmentComponents().forEach(component -> {
            assertNotNull(component.getSpreadRateCode());
            assertNotNull(component.getFundingDesk());
        });
    }

    LOG.debug("testQuery{Entity}SpreadRateCompositeKey - ENDS");
}
```

---

## Validation Test Pattern (common to all)

```java
@Test
public void testBasicValidateCallsIdentifierValidate() throws JsonProcessingException {
    LiqAPIQuery{Entity}Integration liqAPIDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_{ENTITY}_INTEGRATION.toString(),
        LiqAPIQuery{Entity}Integration.class);
    liqAPIDataQuery.basicValidate();
    assertNotNull(liqAPIDataQuery);
}

@Test
public void testValidateLicense() {
    LiqAPIQuery{Entity}Integration liqAPIDataQuery = new LiqAPIQuery{Entity}Integration();
    LiqAPIExecutableData result = liqAPIDataQuery.validateLicense();
    assertNotNull(result);
    assertEquals(liqAPIDataQuery, result);
}
```
