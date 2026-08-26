package com.misys.liq.api.rest.executable.loanprincipalpayment;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.*;
import com.misys.liq.api.rest.BaseTestLoanIQ;
import com.misys.liq.api.rest.data.*;
import com.finastra.liq.module.loan.model.LoanPrincipalPayment;
import com.finastra.liq.module.loan.api.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LiqAPIQueryLoanPrincipalPaymentIntegrationTest extends BaseTestLoanIQ {
    // Spreadsheet row: 5 — loanTransactionId
    @Test
    @Order(1)
    public void testQueryPrincipalPaymentValid() throws Exception {
        LiqAPICreateLoanPrincipalPaymentIntegration create = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.CREATE_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPICreateLoanPrincipalPaymentIntegration.class);
        create.setIdempotencyKey(LiqApiDataUtil.generateIdempotencyKey());
        create.basicValidate();
        LiqAPILoanPrincipalPaymentIntegrationAsReturnValue made = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) create.basicExecute();
        LiqAPIQueryLoanPrincipalPaymentIntegration query = LiqApiDataUtil.getObjectFromJson(GeneralIntegrationMapping.QUERY_PRINCIPALPAYMENT_TRANSACTION_INTEGRATION.toString(), LiqAPIQueryLoanPrincipalPaymentIntegration.class);
        query.getOutstandingTransactionIdentifier().setIdentifierValue(made.getLoanTransactionId());
        query.basicValidate();
        LiqAPILoanPrincipalPaymentIntegrationAsReturnValue output = (LiqAPILoanPrincipalPaymentIntegrationAsReturnValue) query.basicExecute();
        assertEquals(made.getLoanTransactionId(), output.getLoanTransactionId());
        assertNotNull(output.getUpdateTimeStamp());
    }

    // Spreadsheet rows: 8-25 — response attributes
    @Test
    @Order(2)
    public void testQueryPrincipalPaymentMappings() {
        assertNotNull(LiqAPIQueryLoanPrincipalPaymentIntegration.clazz.primitiveFieldMappings());
    }
}
