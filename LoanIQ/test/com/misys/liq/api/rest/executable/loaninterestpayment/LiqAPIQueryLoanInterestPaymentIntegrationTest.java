package com.misys.liq.api.rest.executable.loaninterestpayment;

import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.List;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIQueryLoanInterestPaymentIntegrationTest extends BaseTestLoanIQ {

    @Test
    @Order(1)
    public void testQueryInterestPaymentValid() throws JsonProcessingException {
        LOG.debug("In testQueryInterestPaymentValid() - START");

        LiqAPICreateLoanInterestPaymentIntegration createData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.CREATE_INTEREST_PMT_INTEGRATION.toString(),
            LiqAPICreateLoanInterestPaymentIntegration.class);
        createData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        createData.basicValidate();
        List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> createResults =
            (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) createData.basicExecute();
        Assertions.assertNotNull(createResults);
        Assertions.assertFalse(createResults.isEmpty());
        String loanTransactionId = createResults.get(0).getLoanTransactionId();

        LiqAPIQueryLoanInterestPaymentIntegration liqAPIDataQuery =
            (LiqAPIQueryLoanInterestPaymentIntegration) LiqAPIQueryLoanInterestPaymentIntegration.clazz.basicNew();
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(loanTransactionId);
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);

        List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> output =
            (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);

        Assertions.assertNotNull(output);
        Assertions.assertFalse(output.isEmpty());
        Assertions.assertEquals(loanTransactionId, output.get(0).getLoanTransactionId());

        LOG.debug("testQueryInterestPaymentValid - ENDS");
    }

    @Test
    @Order(2)
    public void testQueryInterestPaymentWithUnknownTransactionId() throws JsonProcessingException {
        LOG.debug("In testQueryInterestPaymentWithUnknownTransactionId() - START");

        LiqAPIQueryLoanInterestPaymentIntegration liqAPIDataQuery =
            (LiqAPIQueryLoanInterestPaymentIntegration) LiqAPIQueryLoanInterestPaymentIntegration.clazz.basicNew();
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue("UNKNOWN-TRANSACTION-ID");
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);

        try {
            LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
            Assertions.fail("Expected exception for unknown transaction id");
        } catch (Exception e) {
            Assertions.assertNotNull(e.getMessage());
        }

        LOG.debug("testQueryInterestPaymentWithUnknownTransactionId - ENDS");
    }
}
