package com.misys.liq.api.rest.executable.alternateidentifiers;

import static org.junit.jupiter.api.Assertions.*;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.misys.liq.BaseTestLoanIQ;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIExceptionMessage;
import com.misys.liq.addon.desktopcomm.apicomm.apiexecutor.LiqAPIResponse;
import com.misys.liq.api.rest.constants.GeneralIntegrationMapping;
import java.util.Properties;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

/** Integration tests for the AlternateIdentifiers query API. */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIQueryAlternateIdentifiersIntegrationTest extends BaseTestLoanIQ {
    private static final Logger LOG = LogManager.getLogger(LiqAPIQueryAlternateIdentifiersIntegrationTest.class);
    private LiqAPIAlternateIdentifiersQueryIntegration query;
    private LiqAPIResponse response;

    @BeforeEach
    public void setProperties() {
        Properties props = System.getProperties();
        props.setProperty("RestServices", "Y");
    }

    // Spreadsheet row: 12 — objectType
    @Test @Order(1)
    public void testQueryWithNullObjectType() throws JsonProcessingException {
        query = getMainObjectFromJsonQuery(GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(), LiqAPIAlternateIdentifiersQueryIntegration.class);
        query.getObjectIdentifier().setObjectType(null);
        LOG.debug("Testing AlternateIdentifiers query with null objectType");
        response = (LiqAPIResponse) invokeApiInterface(query);
        assertEquals("false", response.getSuccess());
        assertFalse(response.getAPIMessages().isEmpty());
        response.getAPIMessages().forEach(message -> { if (message instanceof LiqAPIExceptionMessage) LOG.error("Query validation error: " + ((LiqAPIExceptionMessage) message).getMessage()); });
    }

    // Spreadsheet row: 13 — identfierType
    @Test @Order(2)
    public void testQueryWithInvalidIdentifierType() throws JsonProcessingException {
        query = getMainObjectFromJsonQuery(GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(), LiqAPIAlternateIdentifiersQueryIntegration.class);
        query.getObjectIdentifier().setIdentfierType("invalid");
        LOG.debug("Testing AlternateIdentifiers query with invalid identifier type");
        response = (LiqAPIResponse) invokeApiInterface(query);
        assertEquals("false", response.getSuccess());
        assertFalse(response.getAPIMessages().isEmpty());
        response.getAPIMessages().forEach(message -> { if (message instanceof LiqAPIExceptionMessage) LOG.error("Query validation error: " + ((LiqAPIExceptionMessage) message).getMessage()); });
    }

    // Spreadsheet row: 14 — identifierValue
    @Test @Order(3)
    public void testQueryWithNullIdentifierValue() throws JsonProcessingException {
        query = getMainObjectFromJsonQuery(GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(), LiqAPIAlternateIdentifiersQueryIntegration.class);
        query.getObjectIdentifier().setIdentifierValue(null);
        LOG.debug("Testing AlternateIdentifiers query with null identifierValue");
        response = (LiqAPIResponse) invokeApiInterface(query);
        assertEquals("false", response.getSuccess());
        assertFalse(response.getAPIMessages().isEmpty());
        response.getAPIMessages().forEach(message -> { if (message instanceof LiqAPIExceptionMessage) LOG.error("Query validation error: " + ((LiqAPIExceptionMessage) message).getMessage()); });
    }

    // Spreadsheet rows: 12-14 — objectIdentifier
    @Test @Order(4)
    public void testQueryAlternateIdentifiersUsingConfiguredIdentifier() throws JsonProcessingException {
        query = getMainObjectFromJsonQuery(GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(), LiqAPIAlternateIdentifiersQueryIntegration.class);
        LOG.debug("Testing successful AlternateIdentifiers query using the spreadsheet identifier");
        response = (LiqAPIResponse) invokeApiInterface(query);
        assertEquals("true", response.getSuccess());
        assertNotNull(response.getResult());
    }

    // Spreadsheet rows: 17-23 — response attributes
    @Test @Order(5)
    public void testQueryAlternateIdentifiersReturnsResponseAttributes() throws JsonProcessingException {
        query = getMainObjectFromJsonQuery(GeneralIntegrationMapping.QUERY_ALTERNATEIDENTIFIERS_INTEGRATION.toString(), LiqAPIAlternateIdentifiersQueryIntegration.class);
        LOG.debug("Testing AlternateIdentifiers response attributes");
        response = (LiqAPIResponse) invokeApiInterface(query);
        assertEquals("true", response.getSuccess());
        LiqAPIAlternateIdentifiersIntegrationAsReturnValue result = (LiqAPIAlternateIdentifiersIntegrationAsReturnValue) response.getResult();
        assertNotNull(result);
        assertNotNull(result.getSuccess());
        assertNotNull(result.getMessage());
    }
}
