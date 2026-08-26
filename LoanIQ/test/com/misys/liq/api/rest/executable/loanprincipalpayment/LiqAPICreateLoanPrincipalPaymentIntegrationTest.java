package com.misys.liq.api.rest.executable.loanprincipalpayment;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.*;
import com.misys.liq.api.rest.BaseTestLoanIQ;
import com.misys.liq.api.rest.data.*;
import com.finastra.liq.module.loan.model.LoanPrincipalPayment;
import com.finastra.liq.module.loan.api.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPICreateLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {
    // Spreadsheet row: 8 — requestedAmount
    @Test
    @Order(1)
    public void testCreatePrincipalPaymentValid() throws Exception {
        LiqAPICreateLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPICreateLoanPrincipalPaymentIntegration.class);
        data.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        data.basicValidate();
        LiqAPILoanPrincipalPaymentIntegrationAsReturnValue output = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) data.basicExecute();
        assertNotNull(output);
        assertNotNull(output.getLoanTransactionId());
    }

    // Spreadsheet rows: 8-9 — requestedAmount / effectiveDate
    @Test
    @Order(2)
    public void testCreatePrincipalPaymentRequiresCoreFields() throws Exception {
        LiqAPICreateLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPICreateLoanPrincipalPaymentIntegration.class);
        data.setRequestedAmount(null);
        data.setEffectiveDate(null);
        assertThrows(Exception.class, data::basicValidate);
    }

    // Spreadsheet rows: 13-20 — identifier and optional attributes
    @Test
    @Order(3)
    public void testCreatePrincipalPaymentMappings() {
        assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings());
        assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.nonPrimitiveFieldMappings());
    }
}
