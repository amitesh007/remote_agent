# Code Pattern Examples — Consolidated from All Create-Test Skills

This file contains **all code patterns as-is** from the individual `*-create-test` skills. These serve as reference patterns when the generic `lending-create-test-api` skill generates test classes.

---

## Pattern 1: UpfrontFee — invokeApiInterface with LiqAPIResponse

**Source**: `upfrontfee-create-test`

### Positive Test (Success with Response Casting)

```java
@Test
public void testCreateUpfrontFeeWithValidAmount() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_UPFRONTFEE_TRANSACTION_WITH_AMOUNT.toString(),
        LiqAPICreateUpfrontFeeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    LiqAPIUpfrontFeeIntegrationAsReturnValue createResponse =
        (LiqAPIUpfrontFeeIntegrationAsReturnValue) basicExecuteOutput.getResult();
    assertNotNull(createResponse.getTransactionId());
    assertNotNull(createResponse.getUpdateTimeStamp());
    assertEquals("PEND", liqAPIData.getStatusCode());
}
```

### Negative Test (Null Mandatory Field with Message Assert)

```java
@Test
@Order(2)
public void testCreateUpfronfeeWithoutAmount() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_UPFRONTFEE_TRANSACTION_WITHOUT_AMOUNT.toString(),
        LiqAPICreateUpfrontFeeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
}
```

### Idempotency Key Missing Test

```java
@Test
@Order(1)
public void testCreateUpfronfeeWithoutIdempotencyKey() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_UPFRONTFEE_TRANSACTION_WITHOUT_IDEMPOTENCY_KEY.toString(),
        LiqAPICreateUpfrontFeeIntegration.class);
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message ->
        assertEquals("The idempotencyKey is mandatory for POST calls.",
            ((LiqAPIExceptionMessage) message).getMessage()));
}
```

### Invalid Code Table Value Test

```java
@Test
public void testCreateUpfronfeeWithWrongBranchCode() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_UPFRONTFEE_TRANSACTION_WITH_WRONG_EFFECTIVE_DATE.toString(),
        LiqAPICreateUpfrontFeeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message ->
        assertEquals("Value 000031 of field branchCode is not a code in table Branch.",
            ((LiqAPIExceptionMessage) message).getMessage()));
}
```

### Date Test with DateUtility

```java
@Test
public void testCreateUpfrontFeeWithCurrentBusinessDate() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_UPFRONTFEE_TRANSACTION_WITH_AMOUNT.toString(),
        LiqAPICreateUpfrontFeeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.setEffectiveDate(DateUtility.getDateAsFormattedString(new Date(), "yyyy-MM-dd"));
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
}
```

---

## Pattern 2: Deal — invokeApiInterface with getDealId()

**Source**: `deal-create-test`

### Positive Test (Mandatory Fields)

```java
@Test
public void testMandatoryFieldsValidScenario() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_INTEGRATION_MANDATORY.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    LiqAPIDealIntegrationAsReturnValue createResponse =
        (LiqAPIDealIntegrationAsReturnValue) basicExecuteOutput.getResult();
    assertNotNull(createResponse.getDealId());
}
```

### Negative Test (Null Field)

```java
@Test
@Order(1)
public void testCreateDealWithoutDealName() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_INTEGRATION_MANDATORY.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.setDealName(null);
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
}
```

### Security Access Symbol Test

```java
@Test
public void testSecurityAccessSymbol() throws JsonProcessingException {
    LiqAPICreateDealIntegration data = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_DEAL_INTEGRATION_MANDATORY.toString(),
        LiqAPICreateDealIntegration.class);
    assertEquals("CreateDealIntegration", data.securityAccessSymbol());
}
```

### Complex Object Template Test

```java
@Test
public void testCreateDealWithAdminAgent() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_INTEGRATION_WITH_ADMIN_AGENT.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
}
```

### All Attributes Combined Test

```java
@Test
public void testCreateDealWithAllAttributes() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_INTEGRATION_ALL_ATTRIBUTES.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    LiqAPIDealIntegrationAsReturnValue r =
        (LiqAPIDealIntegrationAsReturnValue) basicExecuteOutput.getResult();
    assertNotNull(r.getDealId());
}
```

### Additional @BeforeEach Pattern (with IntegrationAPIMode)

```java
@BeforeEach
public void setProperties() {
    Properties props = System.getProperties();
    props.setProperty("RestServices", "Y");
    LoanIQ.currentSession().setIntegrationAPIMode(Boolean.TRUE);
}
```

---

## Pattern 3: Facility — invokeApiInterface with getId()

**Source**: `facility-create-test`

### Positive Test (Primitive Fields)

```java
@Test
public void testCreateFacilityPrimitiveFields() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_FACILITY_INTEGRATION_PRIMITIVE.toString(),
        LiqAPICreateFacilityIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    LiqAPIFacilityIntegrationAsReturnValue r =
        (LiqAPIFacilityIntegrationAsReturnValue) basicExecuteOutput.getResult();
    assertNotNull(r.getId());
}
```

### Negative Test (Null Mandatory Field)

```java
@Test
@Order(1)
public void testCreateFacilityWithoutFacilityName() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_FACILITY_INTEGRATION_PRIMITIVE.toString(),
        LiqAPICreateFacilityIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.setFacilityName(null);
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
}
```

### Null Deal Identifier Test

```java
@Test
@Order(2)
public void testCreateFacilityNullDealIdentifier() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_FACILITY_INTEGRATION_NULL_DEAL_IDENTIFIER.toString(),
        LiqAPICreateFacilityIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
}
```

### Feature-Specific Template Tests (Complex Lists)

```java
@Test
public void testCreateFacilityWithFeePricing() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_FACILITY_INTEGRATION_WITH_FEE_PRICING.toString(),
        LiqAPICreateFacilityIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
}

@Test
public void testCreateFacilityWithMISCodes() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_FACILITY_INTEGRATION_WITH_MIS_CODES.toString(),
        LiqAPICreateFacilityIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
}

@Test
public void testCreateFacilityWithRiskTypes() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_FACILITY_INTEGRATION_WITH_RISK_TYPES.toString(),
        LiqAPICreateFacilityIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
}
```

### Validation-Specific Template Test

```java
@Test
public void testCreateFacilityWithPenaltySpreadValidation() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_FACILITY_INTEGRATION_WITH_PENALTY_SPREAD_VALIDATION.toString(),
        LiqAPICreateFacilityIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
}
```

---

## Pattern 4: LoanDrawdown — callBasicValidate + setParents + callBasicExecute

**Source**: `loandrawdown-create-test`

### Positive Test (Validate → SetParents → Execute)

```java
@Test
@Order(1)
public void testCreateLoanDrawdownValid() throws JsonProcessingException {
    LOG.debug("In testCreateLoanDrawdownValid() - START");

    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_DRAWDOWN_VALID.toString(),
        LiqAPICreateLoanDrawdownIntegration.class);
    int randomSixDigit = 100000 + (int) (Math.random() * 900000);
    liqAPIData.getOutstandingIdentifier().setIdentifierValue("BORROWER " + randomSixDigit);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqApiDataUtil.callBasicValidate(liqAPIData);
    liqAPIData.setParents();

    basicExecuteOutput = (LiqAPILoanDrawdownIntegrationAsReturnValue)
        LiqApiDataUtil.callBasicExecute(liqAPIData);

    Assertions.assertNotNull(basicExecuteOutput);
    Assertions.assertNotNull(basicExecuteOutput.getLoanTransactionId());
    Assertions.assertNotNull(basicExecuteOutput.getLoanId());
    Assertions.assertNotNull(basicExecuteOutput.getUpdateTimeStamp());

    LOG.debug("testCreateLoanDrawdownValid - ENDS");
}
```

### Negative Test (Duplicate Alias with Exception Catch)

```java
@Test
@Order(2)
public void testCreateLoanDrawdownWithDuplicateAlias() throws JsonProcessingException {
    LOG.debug("In testCreateLoanDrawdownWithDuplicateAlias() - START");

    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_DRAWDOWN_VALID.toString(),
        LiqAPICreateLoanDrawdownIntegration.class);
    liqAPIData.getOutstandingIdentifier().setIdentifierValue(TestDataConstants.EXISTING_LOAN_ALIAS);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqApiDataUtil.callBasicValidate(liqAPIData);
    liqAPIData.setParents();

    try {
        basicExecuteOutput = (LiqAPILoanDrawdownIntegrationAsReturnValue)
            LiqApiDataUtil.callBasicExecute(liqAPIData);
    } catch (Exception e) {
        Assertions.assertEquals(
            String.format(ErrorMessageConstants.ALIAS_BORROWER_ALREADY_IN_USE,
                TestDataConstants.EXISTING_LOAN_ALIAS),
            e.getMessage());
    }

    LOG.debug("testCreateLoanDrawdownWithDuplicateAlias - ENDS");
}
```

### Composite Key Pattern

```java
@Test
public void testCreateLoanDrawdownCompositeKey() throws JsonProcessingException {
    LOG.debug("In testCreateLoanDrawdownCompositeKey() - START");

    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_DRAWDOWN_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPICreateLoanDrawdownIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.spreadAdjApplies = true;

    basicExecuteOutput = (LiqAPILoanDrawdownIntegrationAsReturnValue)
        LiqApiDataUtil.callBasicExecute(liqAPIData);

    Assertions.assertNotNull(basicExecuteOutput);

    LOG.debug("testCreateLoanDrawdownCompositeKey - ENDS");
}
```

### Random Alias Generation Pattern

```java
int randomSixDigit = 100000 + (int) (Math.random() * 900000);
liqAPIData.getOutstandingIdentifier().setIdentifierValue("BORROWER " + randomSixDigit);
```

---

## Pattern 5: Primary — callBasicValidate + callBasicExecute (Circle)

**Source**: `primary-create-test`

### @BeforeEach with Pre-loaded Data

```java
@BeforeEach
public void setProperties() throws JsonProcessingException {
    Properties props = System.getProperties();
    props.setProperty("RestServices", "Y");
    liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRIMARY_CIRCLE_INTEGRATION.toString(),
        LiqAPICreatePrimaryIntegration.class);
}
```

### Positive Test (Validate + Execute)

```java
@Test
@Order(13)
public void testBasicExecute() throws JsonProcessingException {
    liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRIMARY_CIRCLE_INTEGRATION.toString(),
        LiqAPICreatePrimaryIntegration.class);
    LOG.debug("In testBasicExecute - START");
    LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
    liqApiDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPICircleIntegrationAsReturnValue basicExecuteOutputCreate =
        (LiqAPICircleIntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqApiDataCreate);
    assertNotNull(basicExecuteOutputCreate.getCircleId());
    LOG.debug("In testBasicExecute - END");
}
```

### Negative Test (Validation Exception with ErrorMessageConstants)

```java
@Test
@Order(1)
public void testBasicValidateWithoutDealIdentifier() throws JsonProcessingException {
    liqApiDataCreate.setDealIdentifier(null);
    try {
        LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
    } catch (Exception e) {
        assertEquals(ErrorMessageConstants.DEAL_IDENTIFIER_REQUIRED, e.getMessage());
    }
}
```

### Negative Test (RiskBook for Non-Host Bank)

```java
@Test
@Order(1)
public void testBasicValidateWithRiskBookNonHostBank() throws JsonProcessingException {
    liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRIMARY_CIRCLE_INTEGRATION.toString(),
        LiqAPICreatePrimaryIntegration.class);
    liqApiDataCreate.getLenderDetails().getLenderIdentifier().setIdentifierValue("@-B50GAA");
    liqApiDataCreate.getLenderDetails().setBuyerLocation("N");
    try {
        LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
    } catch (Exception e) {
        assertEquals(ErrorMessageConstants.CIRCLE_RISKBOOK_NOT_REQUIRED, e.getMessage());
    }
}
```

### Negative Test (Closed Deal Scenario)

```java
@Test
@Order(10)
public void testCreateCircleOnClosedDeal() throws JsonProcessingException {
    liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRIMARY_CIRCLE_INTEGRATION_CLOSED_DEAL.toString(),
        LiqAPICreatePrimaryIntegration.class);
    LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
    liqApiDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    try {
        LiqApiDataUtil.callBasicExecute(liqApiDataCreate);
    } catch (Exception e) {
        assertEquals("Primary cannot be added to closed host bank deal.", e.getMessage());
    }
}
```

### Negative Test (Already Exists)

```java
@Test
@Order(11)
public void testCreateCircleAlreadyExist() throws JsonProcessingException {
    liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRIMARY_CIRCLE_INTEGRATION_ALREADY_EXIST.toString(),
        LiqAPICreatePrimaryIntegration.class);
    LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
    liqApiDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    try {
        LiqApiDataUtil.callBasicExecute(liqApiDataCreate);
    } catch (Exception e) {
        assertTrue(e.getMessage().contains("is already a primary at"));
    }
}
```

### Sell Amount Validation

```java
@Test
@Order(12)
public void testValidateSellAmount() throws JsonProcessingException {
    liqApiDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRIMARY_CIRCLE_INTEGRATION.toString(),
        LiqAPICreatePrimaryIntegration.class);
    liqApiDataCreate.setSellAmount(BigDecimal.ONE);
    try {
        LiqApiDataUtil.callBasicValidate(liqApiDataCreate);
    } catch (Exception e) {
        assertTrue(e.getMessage().contains("Sum of facility commitment amounts"));
        assertTrue(e.getMessage().contains("does not agree with aggregate amount entered"));
    }
}
```

### Extended Class-Mapping Coverage (Primary-style)

```java
@Test public void testBasicNew() {
    Assertions.assertNotNull(LiqAPICreatePrimaryIntegration.clazz.basicNew());
    Assertions.assertTrue(LiqAPICreatePrimaryIntegration.clazz.basicNew() instanceof LiqAPICreatePrimaryIntegration);
}
@Test public void testJavaClass() {
    Assertions.assertEquals(LiqAPICreatePrimaryIntegration.class, LiqAPICreatePrimaryIntegration.clazz.getJavaClass());
}
@Test public void testStSuperclass() {
    Assertions.assertEquals(LiqAPICreatePrimary.clazz, LiqAPICreatePrimaryIntegration.clazz.getStSuperclass());
}
@Test public void testNonPrimitiveFieldCollectionMappings() {
    List mappings = LiqAPICreatePrimaryIntegration.clazz.nonPrimitiveFieldCollectionMappings();
    Assertions.assertNotNull(mappings);
}
@Test public void testIsRest() {
    Assertions.assertTrue(LiqAPICreatePrimaryIntegration.clazz.isRest());
}
@Test public void testStclass() {
    Assertions.assertEquals(LiqAPICreatePrimaryIntegration.clazz, liqApiDataCreate.getStClass());
}
@Test public void testValidateLicense() {
    Assertions.assertNotNull(liqApiDataCreate.validateLicense());
}
@Test public void testSecurityAccessSymbol() {
    Assertions.assertEquals(APICommonConstants.SECURITY_ACCESS_SYMBOL_CREATE_CIRCLE, liqApiDataCreate.securityAccessSymbol());
}
@Test public void testIsIntegrationAPI() {
    Assertions.assertTrue(liqApiDataCreate.isIntegrationAPI());
}
@Test public void testStatusCode() {
    liqApiDataCreate.setStatusCode("PEND");
    Assertions.assertEquals("PEND", liqApiDataCreate.getStatusCode());
}
```

---

## Pattern 6: LoanInterestPayment — basicValidate + basicExecute (List Return)

**Source**: `loaninterestpayment-create-test`

### Positive Test (List Return Type)

```java
@Test
@Order(1)
public void testCreateInterestPaymentValid() throws JsonProcessingException {
    LOG.debug("In testCreateInterestPaymentValid() - START");

    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_INTEREST_PMT_INTEGRATION.toString(),
        LiqAPICreateLoanInterestPaymentIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.basicValidate();
    List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> results =
        (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) liqAPIData.basicExecute();

    Assertions.assertNotNull(results);
    Assertions.assertFalse(results.isEmpty());
    output = results.get(0);
    Assertions.assertNotNull(output.getLoanTransactionId());
    Assertions.assertNotNull(output.getUpdateTimeStamp());
    Assertions.assertNotNull(output.getEffectiveDate());
    Assertions.assertEquals("PEND", output.getStatusCode());
    Assertions.assertEquals("CreateLoanInterestPaymentIntegration",
        LiqAPICreateLoanInterestPaymentIntegration.clazz.securityAccessSymbol());
    Assertions.assertTrue(LiqAPICreateLoanInterestPaymentIntegration.clazz.isRest());

    LOG.debug("testCreateInterestPaymentValid - ENDS");
}
```

### Negative Test (Try-Catch with fail())

```java
@Test
@Order(2)
public void testCreateInterestPaymentWithNullEffectiveDate() throws JsonProcessingException {
    LOG.debug("In testCreateInterestPaymentWithNullEffectiveDate() - START");

    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_INTEREST_PMT_INTEGRATION.toString(),
        LiqAPICreateLoanInterestPaymentIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.setEffectiveDate(null);

    try {
        liqAPIData.basicValidate();
        liqAPIData.basicExecute();
        Assertions.fail("Expected exception for null effective date");
    } catch (Exception e) {
        Assertions.assertNotNull(e.getMessage());
        Assertions.assertTrue(e.getMessage().contains("Effective Date is required"));
        LOG.debug("Expected error: {}", e.getMessage());
    }

    LOG.debug("testCreateInterestPaymentWithNullEffectiveDate - ENDS");
}
```

### Extended Class-Mapping Coverage (Interest Payment-style)

```java
@Test public void testNonPrimitiveFieldMappings() {
    assertNotNull(LiqAPICreateLoanInterestPaymentIntegration.clazz.nonPrimitiveFieldMappings());
}
@Test public void testPrimitiveFieldMappings() {
    assertNotNull(LiqAPICreateLoanInterestPaymentIntegration.clazz.primitiveFieldMappings());
}
@Test public void testNonPrimitiveFieldCollectionMappings() {
    assertNotNull(LiqAPICreateLoanInterestPaymentIntegration.clazz.nonPrimitiveFieldCollectionMappings());
}
@Test public void testSecurityAccessSymbol() {
    assertEquals("CreateLoanInterestPaymentIntegration",
        LiqAPICreateLoanInterestPaymentIntegration.clazz.securityAccessSymbol());
}
@Test public void testIsRest() {
    assertTrue(LiqAPICreateLoanInterestPaymentIntegration.clazz.isRest());
}
@Test public void testGetStClass() throws JsonProcessingException {
    LiqAPICreateLoanInterestPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_INTEREST_PMT_INTEGRATION.toString(),
        LiqAPICreateLoanInterestPaymentIntegration.class);
    assertNotNull(data.getStClass());
}
@Test public void testGetReturnType() {
    assertNotNull(LiqAPICreateLoanInterestPaymentIntegration.clazz.getReturnType());
}
```

---

## Pattern 7: LoanPrincipalPayment — basicValidate + basicExecute (Direct Cast)

**Source**: `loanprincipalpayment-create-test`

### Positive Test (Direct Cast to Return Value)

```java
@Test
@Order(1)
public void testCreatePrincipalPaymentValid() throws JsonProcessingException {
    LOG.debug("In testCreatePrincipalPaymentValid() - START");

    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPICreateLoanPrincipalPaymentIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());

    liqAPIData.basicValidate();
    basicExecuteOutput = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) liqAPIData.basicExecute();

    Assertions.assertNotNull(basicExecuteOutput);
    Assertions.assertNotNull(basicExecuteOutput.getLoanTransactionId());
    Assertions.assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings());
    Assertions.assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.nonPrimitiveFieldMappings());
    Assertions.assertNotNull(liqAPIData.getStClass());

    LOG.debug("testCreatePrincipalPaymentValid - ENDS");
}
```

### Negative Test (Try-Catch with fail())

```java
@Test
@Order(2)
public void testCreatePrincipalPaymentWithoutRequestedAmount() throws JsonProcessingException {
    LOG.debug("In testCreatePrincipalPaymentWithoutRequestedAmount() - START");

    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPICreateLoanPrincipalPaymentIntegration.class);
    liqAPIData.setRequestedAmount(null);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());

    try {
        liqAPIData.basicValidate();
        basicExecuteOutput = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) liqAPIData.basicExecute();
        Assertions.fail("Expected exception for null requestedAmount");
    } catch (Exception e) {
        Assertions.assertNotNull(e.getMessage());
        LOG.debug("Expected error: {}", e.getMessage());
    }

    LOG.debug("testCreatePrincipalPaymentWithoutRequestedAmount - ENDS");
}
```

### Extended Class-Mapping Coverage (Principal Payment-style)

```java
@Test public void testNonPrimitiveFieldMappings() {
    assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.nonPrimitiveFieldMappings());
}
@Test public void testPrimitiveFieldMappings() {
    assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings());
}
@Test public void testSecurityAccessSymbol() throws JsonProcessingException {
    LiqAPICreateLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPICreateLoanPrincipalPaymentIntegration.class);
    assertNotNull(data.securityAccessSymbol());
}
@Test public void testReturnType() {
    assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.getReturnType());
}
@Test public void testIsRest() {
    assertTrue(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.isRest());
}
@Test public void testGetStClass() throws JsonProcessingException {
    LiqAPICreateLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPICreateLoanPrincipalPaymentIntegration.class);
    assertNotNull(data.getStClass());
}
```

---

## Pattern 8: LoanRepricing — Validate + Execute with Status Assertions

**Source**: `loanrepricing-create-test`

### Positive Test (Status Code Assertion)

```java
@Test
public void testCreateLoanRepricingWithDefaultStatusCode() throws JsonProcessingException {
    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_REPRICING_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPICreateLoanRepricingIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.basicValidate();
    output = (LiqAPILoanRepricingIntegrationAsReturnValue) liqAPIData.basicExecute();
    assertNotNull(output);
    assertEquals("PEND", output.getStatusCode());
}
```

### Negative Test (Invalid Field Value)

```java
@Test
public void testCreateLoanRepricingWithInvalidStatusCode() throws JsonProcessingException {
    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_REPRICING_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPICreateLoanRepricingIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.setStatusCode("INVALID");
    try {
        liqAPIData.basicValidate();
        liqAPIData.basicExecute();
        fail("Expected exception for invalid status code");
    } catch (Exception e) {
        assertNotNull(e.getMessage());
    }
}
```

### Boolean Indicator Positive Test

```java
@Test
public void testCreateLoanRepricingWithSettleLendersNetTrue() throws JsonProcessingException {
    liqAPIData = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_REPRICING_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPICreateLoanRepricingIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.setSettleLendersNetIndicator(true);
    liqAPIData.basicValidate();
    output = (LiqAPILoanRepricingIntegrationAsReturnValue) liqAPIData.basicExecute();
    assertNotNull(output);
}
```

---

## Pattern 9: ProductGuarantee — invokeApiInterface with List Response

**Source**: `productguarantee-create-test`

### Positive Test (ProductGuaranteeIdentifierList)

```java
@Test
public void testCreateProductGuaranteeForFacility() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.ADD_GUARANTEE_FOR_FACILITY.toString(),
        LiqAPIUpdateProductGuaranteeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());
    LiqAPIProductGuaranteeIntegrationAsReturnValue response =
        (LiqAPIProductGuaranteeIntegrationAsReturnValue) basicExecuteOutput.getResult();
    assertNotNull(response);
    assertNotNull(response.getProductGuaranteeIdentifierList());
    assertFalse(response.getProductGuaranteeIdentifierList().isEmpty());
    assertNotNull(response.getProductGuaranteeIdentifierList().get(0).getIdentifierValue());
}
```

### Negative Test (Null Owner Identifier Value)

```java
@Test
@Order(1)
public void testCreateProductGuaranteeWithoutOwnerIdentifierValue() throws JsonProcessingException {
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.ADD_GUARANTEE_FOR_FACILITY.toString(),
        LiqAPIUpdateProductGuaranteeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIData.getOwnerIdentifier().setOwnerIdentifierValue(null);
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("false", basicExecuteOutput.getSuccess());
    basicExecuteOutput.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
}
```

### Response Assertions (ProductGuarantee-specific)

```java
LiqAPIProductGuaranteeIntegrationAsReturnValue response =
    (LiqAPIProductGuaranteeIntegrationAsReturnValue) basicExecuteOutput.getResult();
assertNotNull(response);
assertNotNull(response.getProductGuaranteeIdentifierList());
assertFalse(response.getProductGuaranteeIdentifierList().isEmpty());
assertNotNull(response.getProductGuaranteeIdentifierList().get(0).getIdentifierValue());
assertNotNull(response.getProductGuaranteeIdentifierList().get(0).getUpdateTimeStamp());
assertNotNull(response.getOwnerId());
assertNotNull(response.getOwnerType());
```

---

## Summary — Pattern Selection Guide

| Execution Approach | Business Objects | Key Characteristic |
|---|---|---|
| `invokeApiInterface()` → `LiqAPIResponse` | UpfrontFee, Deal, Facility, ProductGuarantee | Uses `getSuccess()`, `getAPIMessages()`, `getResult()` |
| `callBasicValidate()` + `setParents()` + `callBasicExecute()` | LoanDrawdown | Requires parent linkage before execute |
| `callBasicValidate()` + `callBasicExecute()` | Primary | Exception-based validation (try-catch) |
| `basicValidate()` + `basicExecute()` → List | LoanInterestPayment | Returns `List<ReturnValue>` |
| `basicValidate()` + `basicExecute()` → Direct Cast | LoanPrincipalPayment, LoanRepricing | Returns single object directly |

| Response ID Field | Business Objects |
|---|---|
| `getTransactionId()` | UpfrontFee |
| `getDealId()` | Deal |
| `getId()` | Facility |
| `getLoanTransactionId()` + `getLoanId()` | LoanDrawdown, LoanInterestPayment, LoanPrincipalPayment |
| `getCircleId()` | Primary |
| `getProductGuaranteeIdentifierList()` | ProductGuarantee |
