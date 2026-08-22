# Code Pattern Examples — Consolidated from All Delete-Test Skills

This file contains **all code patterns as-is** from the individual `*-delete-test` skills. These serve as reference patterns when the generic `lending-delete-test-api` skill generates delete test classes.

---

## Pattern 1: Deal — invokeApiInterface with LiqAPIResponse + If-Match

**Source**: `deal-delete-test`

### Positive Test (Success with If-Match Timestamp)

```java
@Test
public void testSuccessfulDeleteById() throws JsonProcessingException {
    LOG.debug("Test: Successful delete by ID - START");

    // STEP 1: CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_INTEGRATION_ALL_ATTRIBUTES_FOR_QUERY.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

    // STEP 2: QUERY
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_DEAL_INTEGRATION.toString(),
        LiqAPIQueryDealIntegration.class);
    liqAPiDataQuery.getDealIdentifier().setIdentifierValue(
        ((LiqAPIDealIntegrationAsReturnValue) basicExecuteOutput.getResult()).getDealId());
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    // STEP 3: DELETE
    liqAPiDataDelete = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.DELETE_DEAL_INTEGRATION.toString(),
        LiqAPIDeleteDealIntegration.class);
    liqAPiDataDelete.getDealIdentifier().setIdentifierType("id");
    liqAPiDataDelete.getDealIdentifier().setIdentifierValue(
        ((LiqAPIDealIntegrationAsReturnValue) basicExecuteOutput.getResult()).getDealId());
    ((List<LiqAPIDealIntegrationAsReturnValue>) basicExecuteQuery.getResult()).stream().forEach(p -> {
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
```

### Negative Test (Null Identifier with Message Assert)

```java
@Test
@Order(1)
public void testDeleteWithoutDealIdentifierValue() throws JsonProcessingException {
    LOG.debug("In testDeleteWithoutDealIdentifierValue - START");

    // STEP 1: CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_INTEGRATION_ALL_ATTRIBUTES_FOR_QUERY.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

    // STEP 2: QUERY
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_DEAL_INTEGRATION.toString(),
        LiqAPIQueryDealIntegration.class);
    liqAPiDataQuery.getDealIdentifier().setIdentifierValue(
        ((LiqAPIDealIntegrationAsReturnValue) basicExecuteOutput.getResult()).getDealId());
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    // STEP 3: DELETE — mutate the field under test then invoke
    liqAPiDataDelete = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.DELETE_DEAL_INTEGRATION.toString(),
        LiqAPIDeleteDealIntegration.class);
    liqAPiDataDelete.getDealIdentifier().setIdentifierValue(null); // field under test
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);

    assertEquals("false", basicExecuteDelete.getSuccess());
    basicExecuteDelete.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
    LOG.debug("In testDeleteWithoutDealIdentifierValue - END");
}
```

---

## Pattern 2: UpfrontFee — invokeApiInterface with If-Match Timestamp from QUERY

**Source**: `upfrontfee-delete-test`

### Positive Test (Full Bootstrap with Fee Alias)

```java
@Test
@Order(11)
public void testSuccessfulDeleteById() throws JsonProcessingException {
    LOG.debug("Test: Successful Delete By Id - START");

    // STEP 1: CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_UPFRONTFEE_TRANSACTION_WITH_AMOUNT.toString(),
        LiqAPICreateUpfrontFeeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

    // STEP 2: QUERY
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_UPFRONTFEE_TRANSACTION.toString(),
        LiqAPIQueryUpfrontFeeIntegration.class);
    liqAPiDataQuery.getUpforntFeeIdentifier().setIdentifierValue(
        ((LiqAPIUpfrontFeeIntegrationAsReturnValue) basicExecuteOutput.getResult()).getTransactionId());
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    // STEP 3: DELETE
    liqAPiDataDelete = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.DELETE_UPFRONTFEE_TRANSACTION.toString(),
        LiqAPIDeleteUpfrontFeeIntegration.class);
    liqAPiDataDelete.getUpfrontFeeIdentifier().setIdentifierType("id");
    liqAPiDataDelete.getUpfrontFeeIdentifier().setIdentifierValue(
        ((LiqAPIUpfrontFeeIntegrationAsReturnValue) basicExecuteOutput.getResult()).getTransactionId());
    ((List<LiqAPIUpfrontFeeIntegrationAsReturnValue>) basicExecuteQuery.getResult()).stream().forEach(p -> {
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
    LOG.debug("Test: Successful Delete By Id - END");
}
```

### Negative Test (Invalid Identifier Type)

```java
@Test
@Order(2)
public void testDeleteWithInvalidUpfrontFeeIdentifierType() throws JsonProcessingException {
    LOG.debug("Test: Delete with invalid identifier type - START");

    // STEP 1: CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_UPFRONTFEE_TRANSACTION_WITH_AMOUNT.toString(),
        LiqAPICreateUpfrontFeeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);

    // STEP 2: QUERY
    liqAPiDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_UPFRONTFEE_TRANSACTION.toString(),
        LiqAPIQueryUpfrontFeeIntegration.class);
    liqAPiDataQuery.getUpforntFeeIdentifier().setIdentifierValue(
        ((LiqAPIUpfrontFeeIntegrationAsReturnValue) basicExecuteOutput.getResult()).getTransactionId());
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);

    // STEP 3: DELETE — mutate identifier type
    liqAPiDataDelete = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.DELETE_UPFRONTFEE_TRANSACTION.toString(),
        LiqAPIDeleteUpfrontFeeIntegration.class);
    liqAPiDataDelete.getUpfrontFeeIdentifier().setIdentifierType("idtype"); // invalid
    liqAPiDataDelete.getUpfrontFeeIdentifier().setIdentifierValue("Invalid");
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);

    assertEquals("false", basicExecuteDelete.getSuccess());
    basicExecuteDelete.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));
    LOG.debug("Test: Delete with invalid identifier type - END");
}
```

---

## Pattern 3: LoanDrawdown — callBasicExecute with Direct Instantiation

**Source**: `loandrawdown-delete-test`

### Positive Test (Direct DTO Instantiation)

```java
@Test
@Order(1)
public void testSuccessfulDeleteByTransactionId() throws JsonProcessingException {
    LOG.debug("In testSuccessfulDeleteByTransactionId - START");

    // STEP 1: CREATE
    liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_DRAWDOWN_VALID.toString(),
        LiqAPICreateLoanDrawdownIntegration.class);
    int randomSixDigit = 100000 + (int) (Math.random() * 900000);
    liqAPIDataCreate.getOutstandingIdentifier().setIdentifierValue("BORROWER " + randomSixDigit);
    LiqApiDataUtil.callBasicValidate(liqAPIDataCreate);
    liqAPIDataCreate.setParents();
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    outputCreate = (LiqAPILoanDrawdownIntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqAPIDataCreate);

    // STEP 2: QUERY
    liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_LOAN_DRAWDOWN_VALID.toString(),
        LiqAPIQueryLoanDrawdownIntegration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    queryOutput = (List<LiqAPILoanDrawdownIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    Assertions.assertNotNull(queryOutput);
    Assertions.assertFalse(queryOutput.isEmpty());

    // STEP 3: DELETE
    liqAPIDataDelete = new LiqAPIDeleteLoanDrawdownIntegration();
    liqAPIDataDelete.setOutstandingTransactionIdentifier(new LiqAPIOutstandingTransactionIdentifier());
    liqAPIDataDelete.getOutstandingTransactionIdentifier().setIdentifierType(
        LiqAPIOutstandingTransactionIdentifier.OutstandingTransactionIdentifierType.transactionId.name());
    liqAPIDataDelete.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());

    // Execute delete
    LiqApiDataUtil.callBasicValidate(liqAPIDataDelete);
    Object deleteResult = LiqApiDataUtil.callBasicExecute(liqAPIDataDelete);
    Assertions.assertNotNull(deleteResult);

    LOG.debug("In testSuccessfulDeleteByTransactionId - END");
}
```

### Negative Test (Null Identifier)

```java
@Test
@Order(2)
public void testDeleteWithoutTransactionIdentifier() throws JsonProcessingException {
    LOG.debug("In testDeleteWithoutTransactionIdentifier - START");

    // STEP 1: CREATE
    liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_DRAWDOWN_VALID.toString(),
        LiqAPICreateLoanDrawdownIntegration.class);
    int randomSixDigit = 100000 + (int) (Math.random() * 900000);
    liqAPIDataCreate.getOutstandingIdentifier().setIdentifierValue("BORROWER " + randomSixDigit);
    LiqApiDataUtil.callBasicValidate(liqAPIDataCreate);
    liqAPIDataCreate.setParents();
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    outputCreate = (LiqAPILoanDrawdownIntegrationAsReturnValue) LiqApiDataUtil.callBasicExecute(liqAPIDataCreate);

    // STEP 2: QUERY
    liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_LOAN_DRAWDOWN_VALID.toString(),
        LiqAPIQueryLoanDrawdownIntegration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    queryOutput = (List<LiqAPILoanDrawdownIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    Assertions.assertNotNull(queryOutput);

    // STEP 3: DELETE — null identifier
    liqAPIDataDelete = new LiqAPIDeleteLoanDrawdownIntegration();
    liqAPIDataDelete.setOutstandingTransactionIdentifier(null); // field under test

    // Execute and expect failure
    Assertions.assertThrows(Exception.class, () -> {
        LiqApiDataUtil.callBasicValidate(liqAPIDataDelete);
    });

    LOG.debug("In testDeleteWithoutTransactionIdentifier - END");
}
```

---

## Pattern 4: LoanPrincipalPayment — callBasicExecute with getForId Verification

**Source**: `loanprincipalpayment-delete-test`

### Positive Test (basicExecute with getForId)

```java
@Test
@Order(1)
public void testDeletePrincipalPaymentValid() throws JsonProcessingException {
    LOG.debug("In testDeletePrincipalPaymentValid - START");

    // STEP 1: CREATE
    liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPICreateLoanPrincipalPaymentIntegration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIDataCreate.basicValidate();
    outputCreate = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) liqAPIDataCreate.basicExecute();
    Assertions.assertNotNull(outputCreate.getLoanTransactionId());

    // STEP 2: QUERY (verify via getForId)
    LoanPrincipalPayment payment = (LoanPrincipalPayment)
        LoanPrincipalPayment.clazz.getForId(outputCreate.getLoanTransactionId());
    Assertions.assertNotNull(payment);

    // STEP 3: DELETE
    liqAPIDataDelete = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.DELETE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
        LiqAPIDeleteLoanPrincipalPaymentIntegration.class);
    liqAPIDataDelete.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPIOutstandingTransactionIdentifier identifier = new LiqAPIOutstandingTransactionIdentifier();
    identifier.setIdentifierType(
        LiqAPIOutstandingTransactionIdentifier.OutstandingTransactionIdentifierType.transactionId.name());
    identifier.setIdentifierValue(outputCreate.getLoanTransactionId());
    liqAPIDataDelete.setOutstandingTransactionIdentifier(identifier);

    liqAPIDataDelete.basicValidate();
    Object deleteResult = liqAPIDataDelete.basicExecute();
    Assertions.assertNotNull(deleteResult);

    LOG.debug("In testDeletePrincipalPaymentValid - END");
}
```

---

## Pattern 5: ProductGuarantee — invokeApiInterface with OwnerIdentifier + Multiple Identifiers

**Source**: `productguarantee-delete-test`

### Positive Test (Delete from Facility with Owner Identifier)

```java
@Test
@Order(1)
public void testDeleteGuaranteeFromFacility() throws JsonProcessingException {
    LOG.debug("In testDeleteGuaranteeFromFacility - START");

    // STEP 1: CREATE (Add Guarantee)
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.ADD_GUARANTEE_FOR_FACILITY.toString(),
        LiqAPIUpdateProductGuaranteeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());

    // STEP 2: QUERY (Extract from CREATE response)
    LiqAPIProductGuaranteeIntegrationAsReturnValue createResult =
        (LiqAPIProductGuaranteeIntegrationAsReturnValue) basicExecuteOutput.getResult();
    String guaranteeId = createResult.getProductGuaranteeIdentifierList().get(0).getIdentifierValue();
    Date updateTimeStamp = createResult.getProductGuaranteeIdentifierList().get(0).getUpdateTimeStamp();

    // STEP 3: DELETE
    liqAPiDataDelete = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.DELETE_GUARANTEE_FROM_FACILITY.toString(),
        LiqAPIDeleteProductGuaranteeIntegration.class);
    liqAPiDataDelete.getOwnerIdentifier().setOwnerIdentifierValue(
        createResult.getOwnerIdentifierValue());
    liqAPiDataDelete.getOwnerIdentifier().setOwnerType(createResult.getOwnerType());
    liqAPiDataDelete.getProductGuaranteeIdentifiers().get(0).setIdentifierType("id");
    liqAPiDataDelete.getProductGuaranteeIdentifiers().get(0).setIdentifierValue(guaranteeId);
    String dateAsFormattedString = DateUtility.getDateAsFormattedString(
        updateTimeStamp, "yyyy-MM-dd HH:mm:ss.S");
    liqAPiDataDelete.setMatchUpdatedTimestamp(dateAsFormattedString);

    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("true", basicExecuteDelete.getSuccess());

    LOG.debug("In testDeleteGuaranteeFromFacility - END");
}
```

### Negative Test (Invalid Owner Type)

```java
@Test
@Order(2)
public void testDeleteWithInvalidOwnerType() throws JsonProcessingException {
    LOG.debug("In testDeleteWithInvalidOwnerType - START");

    // STEP 1: CREATE
    liqAPIData = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.ADD_GUARANTEE_FOR_FACILITY.toString(),
        LiqAPIUpdateProductGuaranteeIntegration.class);
    liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
    assertEquals("true", basicExecuteOutput.getSuccess());

    // STEP 2: QUERY
    LiqAPIProductGuaranteeIntegrationAsReturnValue createResult =
        (LiqAPIProductGuaranteeIntegrationAsReturnValue) basicExecuteOutput.getResult();
    String guaranteeId = createResult.getProductGuaranteeIdentifierList().get(0).getIdentifierValue();
    Date updateTimeStamp = createResult.getProductGuaranteeIdentifierList().get(0).getUpdateTimeStamp();

    // STEP 3: DELETE — set invalid owner type
    liqAPiDataDelete = getMainObjectFromJsonDelete(
        GeneralIntegrationMapping.DELETE_GUARANTEE_FROM_FACILITY.toString(),
        LiqAPIDeleteProductGuaranteeIntegration.class);
    liqAPiDataDelete.getOwnerIdentifier().setOwnerType("INVALID"); // field under test
    liqAPiDataDelete.getProductGuaranteeIdentifiers().get(0).setIdentifierType("id");
    liqAPiDataDelete.getProductGuaranteeIdentifiers().get(0).setIdentifierValue(guaranteeId);
    String dateAsFormattedString = DateUtility.getDateAsFormattedString(
        updateTimeStamp, "yyyy-MM-dd HH:mm:ss.S");
    liqAPiDataDelete.setMatchUpdatedTimestamp(dateAsFormattedString);

    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("false", basicExecuteDelete.getSuccess());
    basicExecuteDelete.getAPIMessages().forEach(message ->
        assertNotNull(((LiqAPIExceptionMessage) message).getMessage()));

    LOG.debug("In testDeleteWithInvalidOwnerType - END");
}
```

---

## Pattern 6: MISCode — invokeApiInterface with OwnerIdentifier + MIS Code List

**Source**: `miscode-delete-test`

### Positive Test (Delete MIS Code from Deal)

```java
@Test
@Order(1)
public void testDeleteMISCodeValid() throws JsonProcessingException {
    LOG.debug("In testDeleteMISCodeValid() - START");

    // STEP 1: CREATE (ensure deal with MIS codes)
    LiqAPICreateDealIntegration liqAPIDataCreate = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_WITH_MISCODE.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPIResponse basicExecuteCreate = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataCreate);
    assertEquals("true", basicExecuteCreate.getSuccess());

    // STEP 2: QUERY (verify MIS codes exist)
    liqAPIDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_MISCODE_INTEGRATION_DEAL.toString(),
        LiqAPIQueryMISCodeIntegration.class);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataQuery);
    assertNotNull(basicExecuteQuery.getResult());
    LiqAPIMISCodeIntegrationAsReturnValue queryResult =
        (LiqAPIMISCodeIntegrationAsReturnValue) ((ArrayList) basicExecuteQuery.getResult()).get(0);
    assertNotNull(queryResult.getMisCodes());
    assertFalse(queryResult.getMisCodes().isEmpty());

    // STEP 3: DELETE
    liqAPIDataDelete = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.DELETE_MISCODE_INTEGRATION_DEAL.toString(),
        LiqAPIDeleteMISCodeIntegration.class);
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataDelete);
    assertEquals("true", basicExecuteDelete.getSuccess());

    LOG.debug("In testDeleteMISCodeValid() - END");
}
```

### Negative Test (Invalid Owner Type)

```java
@Test
@Order(2)
public void testDeleteMISCodeWithInvalidOwnerType() throws JsonProcessingException {
    LOG.debug("In testDeleteMISCodeWithInvalidOwnerType - START");

    // STEP 1: CREATE
    LiqAPICreateDealIntegration liqAPIDataCreate = getMainObjectFromJsonCreate(
        GeneralIntegrationMapping.CREATE_DEAL_WITH_MISCODE.toString(),
        LiqAPICreateDealIntegration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPIResponse basicExecuteCreate = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataCreate);
    assertEquals("true", basicExecuteCreate.getSuccess());

    // STEP 2: QUERY
    liqAPIDataQuery = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.QUERY_MISCODE_INTEGRATION_DEAL.toString(),
        LiqAPIQueryMISCodeIntegration.class);
    basicExecuteQuery = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataQuery);
    assertNotNull(basicExecuteQuery.getResult());

    // STEP 3: DELETE — set invalid owner type
    liqAPIDataDelete = getMainObjectFromJsonQuery(
        GeneralIntegrationMapping.DELETE_MISCODE_INTEGRATION_DEAL.toString(),
        LiqAPIDeleteMISCodeIntegration.class);
    liqAPIDataDelete.getOwnerIdentifier().setOwnerType("INVALID"); // field under test
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPIDataDelete);
    assertEquals("false", basicExecuteDelete.getSuccess());

    LOG.debug("In testDeleteMISCodeWithInvalidOwnerType - END");
}
```

---

## Pattern 7: LoanRepricing — Cancel-as-Delete with basicNew()

**Source**: `loanrepricing-delete-test`

### Positive Test (Cancel with basicNew Instantiation)

```java
@Test
@Order(1)
public void testCancelLoanRepricingValid() throws JsonProcessingException {
    LOG.debug("In testCancelLoanRepricingValid() - START");

    // STEP 1: CREATE
    liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_LOAN_REPRICING_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPICreateLoanRepricingIntegration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIDataCreate.basicValidate();
    outputCreate = (LiqAPILoanRepricingIntegrationAsReturnValue) liqAPIDataCreate.basicExecute();
    Assertions.assertNotNull(outputCreate.getTransactionId());

    // STEP 2: QUERY
    LiqAPIQueryLoanRepricingIntegration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.QUERY_LOAN_REPRICING_SPREAD_MAT_COMPOSITE_KEY.toString(),
        LiqAPIQueryLoanRepricingIntegration.class);
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    List<LiqAPILoanRepricingIntegrationAsReturnValue> queryResults =
        (List<LiqAPILoanRepricingIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    Assertions.assertFalse(queryResults.isEmpty());

    // STEP 3: CANCEL/DELETE
    liqAPIDataCancel = (LiqAPICancelLoanRepricing) LiqAPICancelLoanRepricing.clazz.basicNew();
    liqAPIDataCancel.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPIOutstandingTransactionIdentifier identifier = new LiqAPIOutstandingTransactionIdentifier();
    identifier.setIdentifierType(
        LiqAPIOutstandingTransactionIdentifier.OutstandingTransactionIdentifierType.transactionId.name());
    identifier.setIdentifierValue(outputCreate.getTransactionId());
    liqAPIDataCancel.setOutstandingTransactionIdentifier(identifier);

    // Execute cancel
    liqAPIDataCancel.basicValidate();
    Object cancelResult = liqAPIDataCancel.basicExecute();
    Assertions.assertNotNull(cancelResult);

    LOG.debug("In testCancelLoanRepricingValid() - END");
}
```

---

## Pattern 8: LoanInterestPayment — Cancel-as-Delete with List Response

**Source**: `loaninterestpayment-delete-test`

### Positive Test (Cancel with List<> Create Response)

```java
@Test
@Order(1)
public void testCancelInterestPaymentValid() throws JsonProcessingException {
    LOG.debug("In testCancelInterestPaymentValid() - START");

    // STEP 1: CREATE (returns List)
    liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
        GeneralIntegrationMapping.CREATE_INTEREST_PMT_INTEGRATION.toString(),
        LiqAPICreateLoanInterestPaymentIntegration.class);
    liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    liqAPIDataCreate.basicValidate();
    List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> createResults =
        (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) liqAPIDataCreate.basicExecute();
    Assertions.assertNotNull(createResults);
    Assertions.assertFalse(createResults.isEmpty());
    outputCreate = createResults.get(0);
    Assertions.assertNotNull(outputCreate.getLoanTransactionId());

    // STEP 2: QUERY
    LiqAPIQueryLoanInterestPaymentIntegration liqAPIDataQuery =
        (LiqAPIQueryLoanInterestPaymentIntegration) LiqAPIQueryLoanInterestPaymentIntegration.clazz.basicNew();
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
    LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
    List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> queryResults =
        (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    Assertions.assertFalse(queryResults.isEmpty());

    // STEP 3: CANCEL/DELETE
    liqAPIDataCancel = (LiqAPICancelInterestPayment) LiqAPICancelInterestPayment.clazz.basicNew();
    liqAPIDataCancel.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
    LiqAPIOutstandingTransactionIdentifier identifier = new LiqAPIOutstandingTransactionIdentifier();
    identifier.setIdentifierType(
        LiqAPIOutstandingTransactionIdentifier.OutstandingTransactionIdentifierType.transactionId.name());
    identifier.setIdentifierValue(outputCreate.getLoanTransactionId());
    liqAPIDataCancel.setOutstandingTransactionIdentifier(identifier);

    liqAPIDataCancel.basicValidate();
    Object cancelResult = liqAPIDataCancel.basicExecute();
    Assertions.assertNotNull(cancelResult);

    LOG.debug("In testCancelInterestPaymentValid() - END");
}
```

---

## Pattern 9: Post-Delete Verification (Universal)

**Applies to all delete test classes.**

```java
@Test
public void testDeleted{BusinessObject}IsNotQueryable() throws JsonProcessingException {
    // Full 3-step bootstrap: CREATE → QUERY → DELETE (successful)
    // ... (complete bootstrap per patterns above) ...

    // After successful delete, attempt to query again
    // Pattern A (invokeApiInterface):
    liqAPiDataQuery.get{Identifier}().setIdentifierValue(deletedId);
    LiqAPIResponse requery = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataQuery);
    assertEquals("false", requery.getSuccess());

    // Pattern B (callBasicExecute):
    liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(deletedTransactionId);
    Assertions.assertThrows(Exception.class, () -> {
        LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
    });
}
```

---

## Pattern 10: Class-Mapping Coverage Tests (Universal)

**Applies to all delete test classes.**

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
        GeneralIntegrationMapping.DELETE_{ENUM}.toString(),
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
        GeneralIntegrationMapping.DELETE_{ENUM}.toString(),
        LiqAPIDelete{BusinessObject}Integration.class);
    assertNotNull(data.getStClass());
}
```

---

## Pattern 11: If-Match (Concurrency) Tests

**Source**: `deal-delete-test`, `upfrontfee-delete-test`, `productguarantee-delete-test`

```java
@Test
public void testDeleteWithoutIfMatch() throws JsonProcessingException {
    // Full 3-step bootstrap...
    liqAPiDataDelete.setMatchUpdatedTimestamp(null);
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("false", basicExecuteDelete.getSuccess());
}

@Test
public void testDeleteWithStaleIfMatch() throws JsonProcessingException {
    // Full 3-step bootstrap...
    liqAPiDataDelete.setMatchUpdatedTimestamp("1900-01-01 00:00:00.0");
    basicExecuteDelete = (LiqAPIResponse) this.invokeApiInterface(liqAPiDataDelete);
    assertEquals("false", basicExecuteDelete.getSuccess());
}

@Test
public void testDeleteWithCurrentIfMatch() throws JsonProcessingException {
    // Full 3-step bootstrap with proper timestamp from QUERY...
    assertEquals("true", basicExecuteDelete.getSuccess());
}
```
