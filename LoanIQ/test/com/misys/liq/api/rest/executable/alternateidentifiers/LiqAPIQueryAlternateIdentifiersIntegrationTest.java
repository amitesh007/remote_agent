package com.finastra.liq.api.rest.executable.fee;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

/**
 * Integration coverage for the Alternate Identifiers query endpoint.
 *
 * <p>The request payload is intentionally kept in the repository JSON resource so that each
 * test performs a real API round trip using the same request mapping as the application.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIQueryAlternateIdentifiersIntegrationTest extends BaseTestLoanIQ {

    private static final Logger LOG =
            LogManager.getLogger(LiqAPIQueryAlternateIdentifiersIntegrationTest.class);

    private LiqAPIAlternateIdentifiersQueryIntegration queryData;
    private LiqAPIResponse response;

    @BeforeEach
    public void setProperties() {
        System.setProperty("RestServices", "Y");
    }

    // Spreadsheet row: 12 — objectType
    @Test
    @Order(1)
    public void testQueryAlternateIdentifiersWithNullObjectType() throws JsonProcessingException {
        queryData = getMainObjectFromJsonQuery(
                GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(),
                LiqAPIAlternateIdentifiersQueryIntegration.class);
        queryData.getObjectIdentifier().setObjectType(null);
        LOG.debug("Testing AlternateIdentifiers query with a null object type");

        response = (LiqAPIResponse) invokeApiInterface(queryData);
        assertEquals("false", response.getSuccess());
        response.getAPIMessages().forEach(message -> {
            if (message instanceof LiqAPIExceptionMessage) {
                LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
                LOG.error("Order 1 - API Exception Message: " + exceptionMessage.getMessage());
                assertNotNull(exceptionMessage.getMessage());
            }
        });
    }

    // Spreadsheet row: 13 — identfierType
    @Test
    @Order(2)
    public void testQueryAlternateIdentifiersWithInvalidIdentifierType()
            throws JsonProcessingException {
        queryData = getMainObjectFromJsonQuery(
                GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(),
                LiqAPIAlternateIdentifiersQueryIntegration.class);
        queryData.getObjectIdentifier().setIdentfierType("invalid");
        LOG.debug("Testing AlternateIdentifiers query with an invalid identifier type");

        response = (LiqAPIResponse) invokeApiInterface(queryData);
        assertEquals("false", response.getSuccess());
        response.getAPIMessages().forEach(message -> {
            if (message instanceof LiqAPIExceptionMessage) {
                LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
                LOG.error("Order 2 - API Exception Message: " + exceptionMessage.getMessage());
                assertNotNull(exceptionMessage.getMessage());
            }
        });
    }

    // Spreadsheet row: 14 — identifierValue
    @Test
    @Order(3)
    public void testQueryAlternateIdentifiersWithNullIdentifierValue()
            throws JsonProcessingException {
        queryData = getMainObjectFromJsonQuery(
                GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(),
                LiqAPIAlternateIdentifiersQueryIntegration.class);
        queryData.getObjectIdentifier().setIdentifierValue(null);
        LOG.debug("Testing AlternateIdentifiers query with a null identifier value");

        response = (LiqAPIResponse) invokeApiInterface(queryData);
        assertEquals("false", response.getSuccess());
        response.getAPIMessages().forEach(message -> {
            if (message instanceof LiqAPIExceptionMessage) {
                LiqAPIExceptionMessage exceptionMessage = (LiqAPIExceptionMessage) message;
                LOG.error("Order 3 - API Exception Message: " + exceptionMessage.getMessage());
                assertNotNull(exceptionMessage.getMessage());
            }
        });
    }

    // Spreadsheet row: 12 — objectType
    @Test
    @Order(4)
    public void testQueryAlternateIdentifiersReturnsObjectType() throws JsonProcessingException {
        queryData = getMainObjectFromJsonQuery(
                GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(),
                LiqAPIAlternateIdentifiersQueryIntegration.class);
        LOG.debug("Testing AlternateIdentifiers query response object type");

        response = (LiqAPIResponse) invokeApiInterface(queryData);
        assertEquals("true", response.getSuccess());
        LiqAPIAlternateIdentifiersIntegrationAsReturnValue output =
                (LiqAPIAlternateIdentifiersIntegrationAsReturnValue) response.getResult();
        assertNotNull(output);
        assertNotNull(output.getHasSchedule());
        assertNotNull(output.getScheduleType());
        assertNotNull(output.getObjectIdentifier());
    }

    // Spreadsheet row: 22 — identfierType
    @Test
    @Order(5)
    public void testQueryAlternateIdentifiersReturnsIdentifierType()
            throws JsonProcessingException {
        queryData = getMainObjectFromJsonQuery(
                GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(),
                LiqAPIAlternateIdentifiersQueryIntegration.class);
        LOG.debug("Testing AlternateIdentifiers query response identifier type");

        response = (LiqAPIResponse) invokeApiInterface(queryData);
        assertEquals("true", response.getSuccess());
        LiqAPIAlternateIdentifiersIntegrationAsReturnValue output =
                (LiqAPIAlternateIdentifiersIntegrationAsReturnValue) response.getResult();
        assertNotNull(output);
        assertFalse(output.getObjectIdentifier().isEmpty());
    }

    // Spreadsheet row: 23 — identifierValue
    @Test
    @Order(6)
    public void testQueryAlternateIdentifiersReturnsIdentifierValue()
            throws JsonProcessingException {
        queryData = getMainObjectFromJsonQuery(
                GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(),
                LiqAPIAlternateIdentifiersQueryIntegration.class);
        LOG.debug("Testing AlternateIdentifiers query response identifier value");

        response = (LiqAPIResponse) invokeApiInterface(queryData);
        assertEquals("true", response.getSuccess());
        LiqAPIAlternateIdentifiersIntegrationAsReturnValue output =
                (LiqAPIAlternateIdentifiersIntegrationAsReturnValue) response.getResult();
        assertNotNull(output);
        assertFalse(output.getObjectIdentifier().isEmpty());
    }
}
