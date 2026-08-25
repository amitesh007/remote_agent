package com.misys.liq.api.rest.executable.loanprincipalpayment;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
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
public class LiqAPICreateLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
        LogManager.getLogger(LiqAPICreateLoanPrincipalPaymentIntegrationTest.class);

    private LiqAPICreateLoanPrincipalPaymentIntegration liqAPIData;
    private LiqAPIResponse basicExecuteOutput;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }

    @Test
    @Order(1)
    public void testCreateLoanPrincipalPaymentWithoutIdempotencyKey() throws JsonProcessingException {
        LOG.debug("In testCreateLoanPrincipalPaymentWithoutIdempotencyKey() - START");

        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPICreateLoanPrincipalPaymentIntegration.class);

        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
        assertEquals("false", basicExecuteOutput.getSuccess());
        basicExecuteOutput.getAPIMessages().forEach(message ->
            assertEquals("The idempotencyKey is mandatory for POST calls.",
                ((LiqAPIExceptionMessage) message).getMessage()));

        LOG.debug("In testCreateLoanPrincipalPaymentWithoutIdempotencyKey() - END");
    }

    @Test
    @Order(2)
    public void testCreateLoanPrincipalPaymentWithAllMandatoryFields() throws JsonProcessingException {
        LOG.debug("In testCreateLoanPrincipalPaymentWithAllMandatoryFields() - START");

        liqAPIData = getMainObjectFromJsonCreate(
            GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPICreateLoanPrincipalPaymentIntegration.class);
        liqAPIData.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());

        basicExecuteOutput = (LiqAPIResponse) this.invokeApiInterface(liqAPIData);
        assertEquals("true", basicExecuteOutput.getSuccess());
        assertNotNull(basicExecuteOutput.getResult());

        LOG.debug("In testCreateLoanPrincipalPaymentWithAllMandatoryFields() - END");
    }

    @Test
    public void testNonPrimitiveFieldMappings() {
        assertFalse(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.nonPrimitiveFieldMappings().isEmpty());
    }

    @Test
    public void testPrimitiveFieldMappings() {
        assertFalse(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings().isEmpty());
    }

    @Test
    public void testSecurityAccessSymbol() throws JsonProcessingException {
        LiqAPICreateLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(
            GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(),
            LiqAPICreateLoanPrincipalPaymentIntegration.class);
        assertEquals("CreateLoanPrincipalPaymentIntegration", data.securityAccessSymbol());
    }
}
