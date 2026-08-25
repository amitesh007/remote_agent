package com.misys.liq.api.rest.executable.loaninterestpayment;

import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.List;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPICreateLoanInterestPaymentIntegrationTest extends BaseTestLoanIQ {

    @Test
    @Order(1)
    public void testCreateInterestPaymentValid() throws JsonProcessingException {
        LOG.debug("In testCreateInterestPaymentValid() - START");

        LiqAPICreateLoanInterestPaymentIntegration liqAPIData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.CREATE_INTEREST_PMT_INTEGRATION.toString(),
            LiqAPICreateLoanInterestPaymentIntegration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIData.basicValidate();

        List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> results =
            (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) liqAPIData.basicExecute();

        Assertions.assertNotNull(results);
        Assertions.assertFalse(results.isEmpty());
        LiqAPILoanInterestPaymentIntegrationAsReturnValue output = results.get(0);
        Assertions.assertNotNull(output.getLoanTransactionId());
        Assertions.assertNotNull(output.getUpdateTimeStamp());
        Assertions.assertNotNull(output.getEffectiveDate());
        Assertions.assertEquals("PEND", output.getStatusCode());
        Assertions.assertEquals("CreateLoanInterestPaymentIntegration",
            LiqAPICreateLoanInterestPaymentIntegration.clazz.securityAccessSymbol());
        Assertions.assertTrue(LiqAPICreateLoanInterestPaymentIntegration.clazz.isRest());

        LOG.debug("testCreateInterestPaymentValid - ENDS");
    }

    @Test
    @Order(2)
    public void testCreateInterestPaymentWithNullEffectiveDate() throws JsonProcessingException {
        LOG.debug("In testCreateInterestPaymentWithNullEffectiveDate() - START");

        LiqAPICreateLoanInterestPaymentIntegration liqAPIData = LiqApiDataUtil.getObjectFromJson(
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

    @Test
    @Order(3)
    public void testNonPrimitiveFieldMappings() {
        Assertions.assertNotNull(LiqAPICreateLoanInterestPaymentIntegration.clazz.nonPrimitiveFieldMappings());
    }

    @Test
    @Order(4)
    public void testPrimitiveFieldMappings() {
        Assertions.assertNotNull(LiqAPICreateLoanInterestPaymentIntegration.clazz.primitiveFieldMappings());
    }

    @Test
    @Order(5)
    public void testNonPrimitiveFieldCollectionMappings() {
        Assertions.assertNotNull(LiqAPICreateLoanInterestPaymentIntegration.clazz.nonPrimitiveFieldCollectionMappings());
    }

    @Test
    @Order(6)
    public void testGetReturnType() {
        Assertions.assertNotNull(LiqAPICreateLoanInterestPaymentIntegration.clazz.getReturnType());
    }
}
