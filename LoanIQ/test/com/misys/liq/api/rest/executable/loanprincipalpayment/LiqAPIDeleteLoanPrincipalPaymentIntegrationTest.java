package com.misys.liq.api.rest.executable.loanprincipalpayment;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.*;
import com.misys.liq.api.rest.BaseTestLoanIQ;
import com.misys.liq.api.rest.data.*;
import com.finastra.liq.module.loan.model.LoanPrincipalPayment;
import com.finastra.liq.module.loan.api.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIDeleteLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {
    @Test
    @Order(1)
    // Spreadsheet row: 11 — loanTransactionId
    public void testDeletePrincipalPaymentValid() throws Exception {
        LiqAPICreateLoanPrincipalPaymentIntegration create = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPICreateLoanPrincipalPaymentIntegration.class);
        create.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        create.basicValidate();
        LiqAPILoanPrincipalPaymentIntegrationAsReturnValue made = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) create.basicExecute();
        assertNotNull(LoanPrincipalPayment.clazz.getForId(made.getLoanTransactionId()));
        LiqAPIDeleteLoanPrincipalPaymentIntegration delete = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.DELETE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPIDeleteLoanPrincipalPaymentIntegration.class);
        delete.getOutstandingTransactionIdentifier().setIdentifierValue(made.getLoanTransactionId());
        delete.basicValidate();
        assertNotNull(delete.basicExecute());
    }

    @Test
    @Order(2)
    // Spreadsheet rows: 14-16 — success / message / updateTimeStamp
    public void testDeletePrincipalPaymentMappings() {
        assertNotNull(LiqAPIDeleteLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings());
    }
}
