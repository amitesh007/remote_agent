package com.misys.liq.api.rest.executable.loaninterestpayment;

import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.List;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIUpdateLoanInterestPaymentIntegrationTest extends BaseTestLoanIQ {

    @Test
    @Order(1)
    public void testUpdatePaymentValid() throws JsonProcessingException {
        LOG.debug("In testUpdatePaymentValid() - START");

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

        LiqAPIQueryLoanInterestPaymentIntegration liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.QUERY_INTEREST_PMT_INTEGRATION.toString(),
            LiqAPIQueryLoanInterestPaymentIntegration.class);
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);
        List<LiqAPILoanInterestPaymentIntegrationAsReturnValue> queryResults =
            (List<LiqAPILoanInterestPaymentIntegrationAsReturnValue>) LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
        Assertions.assertFalse(queryResults.isEmpty());
        String timestampFromQuery = queryResults.get(0).getUpdateTimeStamp().toString();

        LiqAPIUpdateLoanInterestPaymentIntegration liqAPIDataUpdate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.UPDATE_INTEREST_PMT_INTEGRATION.toString(),
            LiqAPIUpdateLoanInterestPaymentIntegration.class);
        liqAPIDataUpdate.getOutstandingTransactionIdentifier().setIdentifierValue(outputCreate.getLoanTransactionId());
        liqAPIDataUpdate.setMatchUpdatedTimestamp(timestampFromQuery);
        liqAPIDataUpdate.basicValidate();
        LiqAPILoanInterestPaymentIntegrationAsReturnValue outputUpdate =
            (LiqAPILoanInterestPaymentIntegrationAsReturnValue) liqAPIDataUpdate.basicExecute();

        Assertions.assertNotNull(outputUpdate);
        Assertions.assertNotNull(outputUpdate.getLoanTransactionId());
        Assertions.assertNotNull(outputUpdate.getUpdateTimeStamp());

        LOG.debug("testUpdatePaymentValid - ENDS");
    }

    @Test
    @Order(2)
    public void testUpdatePaymentWithInvalidTimestamp() throws JsonProcessingException {
        LOG.debug("In testUpdatePaymentWithInvalidTimestamp() - START");

        LiqAPIUpdateLoanInterestPaymentIntegration liqAPIDataUpdate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.UPDATE_INTEREST_PMT_INTEGRATION.toString(),
            LiqAPIUpdateLoanInterestPaymentIntegration.class);
        liqAPIDataUpdate.setMatchUpdatedTimestamp("invalid-timestamp");

        try {
            liqAPIDataUpdate.basicValidate();
            liqAPIDataUpdate.basicExecute();
            Assertions.fail("Expected exception for invalid timestamp");
        } catch (Exception e) {
            Assertions.assertNotNull(e.getMessage());
            Assertions.assertTrue(e.getMessage().contains("matchUpdatedTimestamp") || e.getMessage().contains("timestamp"));
        }

        LOG.debug("testUpdatePaymentWithInvalidTimestamp - ENDS");
    }
}
