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
public class LiqAPIUpdateLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPIUpdateLoanPrincipalPaymentIntegrationTest.class);

    private LiqAPICreateLoanPrincipalPaymentIntegration liqAPIDataCreate;
    private LiqAPIUpdateLoanPrincipalPaymentIntegration liqAPIDataUpdate;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }

    @Test
    @Order(1)
    public void testUpdatePrincipalPaymentValid() throws JsonProcessingException {
        LOG.debug("In testUpdatePrincipalPaymentValid() - START");

        liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPICreateLoanPrincipalPaymentIntegration.class);
        liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataCreate.basicValidate();
        Object createOutput = liqAPIDataCreate.basicExecute();
        assertNotNull(createOutput);

        liqAPIDataUpdate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.UPDATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPIUpdateLoanPrincipalPaymentIntegration.class);
        liqAPIDataUpdate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataUpdate.basicValidate();

        Object updateOutput = liqAPIDataUpdate.basicExecute();
        assertNotNull(updateOutput);

        LOG.debug("testUpdatePrincipalPaymentValid - ENDS");
    }

    @Test
    public void testNonPrimitiveFieldMappings() {
        assertFalse(LiqAPIUpdateLoanPrincipalPaymentIntegration.clazz.nonPrimitiveFieldMappings().isEmpty());
    }

    @Test
    public void testPrimitiveFieldMappings() {
        assertFalse(LiqAPIUpdateLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings().isEmpty());
    }

    @Test
    public void testSecurityAccessSymbol() throws JsonProcessingException {
        LiqAPIUpdateLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.UPDATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPIUpdateLoanPrincipalPaymentIntegration.class);
        assertEquals("UpdateLoanPrincipalPaymentIntegration", data.securityAccessSymbol());
    }
}
