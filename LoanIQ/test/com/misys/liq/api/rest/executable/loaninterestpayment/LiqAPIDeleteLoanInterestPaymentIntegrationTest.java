package com.misys.liq.api.rest.executable.loaninterestpayment;

import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.List;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIDeleteLoanInterestPaymentIntegrationTest extends BaseTestLoanIQ {

    @Test
    @Order(1)
    public void testCancelInterestPaymentValid() throws JsonProcessingException {
        LOG.debug("In testCancelInterestPaymentValid() - START");

        LiqAPICreateLoanInterestPaymentIntegration liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.CREATE_INTEREST_PMT_INTEGRATION.toString(),
            LiqAPICreateLoanInterestPaymentIntegration.class);
        liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataCreate.basicValidate();
        List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> createResults =
            (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) liqAPIDataCreate.basicExecute();
        Assertions.assertNotNull(createResults);
        Assertions.assertFalse(createResults.isEmpty());
        LiqAPILoanInterestPaymentIntegrationAsReturnValue outputCreate = createResults.get(0);
        Assertions.assertNotNull(outputCreate.getLoanTransactionId());

        LiqAPIQueryLoanInterestPaymentIntegration liqAPIDataQuery =
            (LiqAPIQueryLoanInterestPaymentIntegration) LiqAPIQueryLoanInterestPaymentIntegration.clazz.basicNew();
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
        List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> queryResults =
            (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
        Assertions.assertFalse(queryResults.isEmpty());

        LiqAPICancelInterestPayment liqAPIDataCancel = (LiqAPICancelInterestPayment) LiqAPICancelInterestPayment.clazz.basicNew();
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

    @Test
    @Order(2)
    public void testCancelInterestPaymentWithMissingIdentifier() throws JsonProcessingException {
        LOG.debug("In testCancelInterestPaymentWithMissingIdentifier() - START");

        LiqAPICancelInterestPayment liqAPIDataCancel = (LiqAPICancelInterestPayment) LiqAPICancelInterestPayment.clazz.basicNew();
        liqAPIDataCancel.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());

        try {
            liqAPIDataCancel.basicValidate();
            liqAPIDataCancel.basicExecute();
            Assertions.fail("Expected exception for missing outstanding transaction identifier");
        } catch (Exception e) {
            Assertions.assertNotNull(e.getMessage());
        }

        LOG.debug("In testCancelInterestPaymentWithMissingIdentifier() - END");
    }
}
