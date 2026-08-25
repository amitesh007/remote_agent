package com.misys.liq.api.rest.executable.loanprincipalpayment;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
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
public class LiqAPIQueryLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPIQueryLoanPrincipalPaymentIntegrationTest.class);

    private LiqAPIQueryLoanPrincipalPaymentIntegration liqAPIDataQuery;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }

    @Test
    @Order(1)
    public void testQueryLoanPrincipalPaymentValid() throws JsonProcessingException {
        LOG.debug("In testQueryLoanPrincipalPaymentValid() - START");

        LiqAPICreateLoanPrincipalPaymentIntegration createData = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPICreateLoanPrincipalPaymentIntegration.class);
        createData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        createData.basicValidate();
        Object createOutput = createData.basicExecute();
        assertNotNull(createOutput);
        String transactionId = String.valueOf(createOutput);

        liqAPIDataQuery = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.QUERY_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPIQueryLoanPrincipalPaymentIntegration.class);
        liqAPIDataQuery.getOutstandingTransactionIdentifier().setIdentifierValue(transactionId);
        LiqApiDataUtil.callBasicValidate(liqAPIDataQuery);

        Object queryOutput = LiqApiDataUtil.callBasicExecute(liqAPIDataQuery);
        assertNotNull(queryOutput);

        LOG.debug("testQueryLoanPrincipalPaymentValid - ENDS");
    }

    @Test
    public void testNonPrimitiveFieldMappings() {
        assertFalse(LiqAPIQueryLoanPrincipalPaymentIntegration.clazz.nonPrimitiveFieldMappings().isEmpty());
    }

    @Test
    public void testPrimitiveFieldMappings() {
        assertFalse(LiqAPIQueryLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings().isEmpty());
    }

    @Test
    public void testSecurityAccessSymbol() throws JsonProcessingException {
        LiqAPIQueryLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.QUERY_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPIQueryLoanPrincipalPaymentIntegration.class);
        assertEquals("QueryLoanPrincipalPaymentIntegration", data.securityAccessSymbol());
    }
}
