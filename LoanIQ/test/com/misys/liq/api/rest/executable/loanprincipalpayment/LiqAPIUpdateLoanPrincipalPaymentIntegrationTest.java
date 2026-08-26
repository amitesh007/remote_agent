package com.misys.liq.api.rest.executable.loanprincipalpayment;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.*;
import com.misys.liq.api.rest.BaseTestLoanIQ;
import com.misys.liq.api.rest.data.*;
import com.finastra.liq.module.loan.model.LoanPrincipalPayment;
import com.finastra.liq.module.loan.api.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIUpdateLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {
    // Spreadsheet rows: 7-9 — requestedAmount / effectiveDate / loanTransactionId
    @Test
    @Order(1)
    public void testUpdatePrincipalPaymentValid() throws Exception {
        LiqAPICreateLoanPrincipalPaymentIntegration create = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPICreateLoanPrincipalPaymentIntegration.class);
        create.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        create.basicValidate();
        LiqAPILoanPrincipalPaymentIntegrationAsReturnValue made = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) create.basicExecute();
        LoanPrincipalPayment outstanding = (LoanPrincipalPayment) LoanPrincipalPayment.clazz.getForId(made.getLoanTransactionId());
        assertNotNull(outstanding);
        LiqAPIUpdateLoanPrincipalPaymentIntegration update = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.UPDATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPIUpdateLoanPrincipalPaymentIntegration.class);
        update.loanTransactionId = made.getLoanTransactionId();
        update.outstandingTran = outstanding;
        update.setMatchUpdatedTimestamp(outstanding.getUpdateTimeStamp().toString());
        update.basicValidate();
        LiqAPILoanPrincipalPaymentIntegrationAsReturnValue result = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) update.basicExecute();
        assertNotNull(result.getLoanTransactionId());
        assertNotNull(result.getUpdateTimeStamp());
    }

    // Spreadsheet rows: 10-20 — read-only and optional fields
    @Test
    @Order(2)
    public void testUpdatePrincipalPaymentMappings() {
        assertNotNull(LiqAPIUpdateLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings());
    }
}
