package com.misys.liq.api.rest.executable.loanprincipalpayment;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.*;
import com.misys.liq.api.rest.BaseTestLoanIQ;
import com.misys.liq.api.rest.data.*;
import com.finastra.liq.module.loan.model.LoanPrincipalPayment;
import com.finastra.liq.module.loan.api.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPICreateLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {
    @Test
    @Order(1)
    // Spreadsheet row: 8 — requestedAmount
    public void testCreatePrincipalPaymentValid() throws Exception {
        LiqAPICreateLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPICreateLoanPrincipalPaymentIntegration.class);
        data.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        data.basicValidate();
        LiqAPILoanPrincipalPaymentIntegrationAsReturnValue output = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) data.basicExecute();
        assertNotNull(output);
        assertNotNull(output.getLoanTransactionId());
    }

    @Test
    @Order(2)
    // Spreadsheet rows: 8-9 — requestedAmount / effectiveDate
    public void testCreatePrincipalPaymentRequiresCoreFields() throws Exception {
        LiqAPICreateLoanPrincipalPaymentIntegration data = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPICreateLoanPrincipalPaymentIntegration.class);
        data.setRequestedAmount(null);
        data.setEffectiveDate(null);
        assertThrows(Exception.class, data::basicValidate);
    }

    @Test
    @Order(3)
    // Spreadsheet rows: 13-20 — identifier and optional attributes
    public void testCreatePrincipalPaymentMappings() {
        assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings());
        assertNotNull(LiqAPICreateLoanPrincipalPaymentIntegration.clazz.nonPrimitiveFieldMappings());
    }
}
