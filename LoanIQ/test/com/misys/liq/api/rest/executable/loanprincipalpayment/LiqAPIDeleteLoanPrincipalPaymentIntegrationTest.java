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
public class LiqAPIDeleteLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPIDeleteLoanPrincipalPaymentIntegrationTest.class);

    private LiqAPICreateLoanPrincipalPaymentIntegration liqAPIDataCreate;
    private LiqAPIDeleteLoanPrincipalPaymentIntegration liqAPIDataDelete;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }

    @Test
    @Order(1)
    public void testDeleteLoanPrincipalPaymentById() throws JsonProcessingException {
        LOG.debug("In testDeleteLoanPrincipalPaymentById() - START");

        liqAPIDataCreate = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPICreateLoanPrincipalPaymentIntegration.class);
        liqAPIDataCreate.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataCreate.basicValidate();
        Object createOutput = liqAPIDataCreate.basicExecute();
        assertNotNull(createOutput);

        liqAPIDataDelete = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.DELETE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPIDeleteLoanPrincipalPaymentIntegration.class);
        liqAPIDataDelete.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        liqAPIDataDelete.basicValidate();

        Object deleteOutput = liqAPIDataDelete.basicExecute();
        assertNotNull(deleteOutput);

        LOG.debug("In testDeleteLoanPrincipalPaymentById() - END");
    }

    @Test
    public void testNonPrimitiveFieldMappings() {
        assertFalse(LiqAPIDeleteLoanPrincipalPaymentIntegration.clazz.nonPrimitiveFieldMappings().isEmpty());
    }

    @Test
    public void testPrimitiveFieldMappings() {
        assertFalse(LiqAPIDeleteLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings().isEmpty());
    }

    @Test
    public void testSecurityAccessSymbol() throws JsonProcessingException {
        LiqAPIDeleteLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.DELETE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPIDeleteLoanPrincipalPaymentIntegration.class);
        assertEquals("DeleteLoanPrincipalPaymentIntegration", data.securityAccessSymbol());
    }
}
