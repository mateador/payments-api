package com.example.paymentsapi.repository;

import com.example.paymentsapi.model.PaymentRequest;
import com.example.paymentsapi.model.PaymentResponse;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.Map;

@Repository
public class PaymentRepository {

    // IN parameters (from request payload)
    private static final String PARAM_P_ACCOUNT_ID_IN = "p_account_id";
    private static final String PARAM_P_AMOUNT_IN = "p_amount";
    private static final String PARAM_P_CURRENCY_IN = "p_currency";
    private static final String PARAM_P_MERCHANT_ID_IN = "p_merchant_id";
    private static final String PARAM_P_IDEMPOTENCY_KEY_IN = "p_idempotency_key";

    // OUT parameters (map to response payload)
    private static final String PARAM_P_TRANSACTION_ID_OUT = "P_TRANSACTION_ID";
    private static final String PARAM_P_STATUS_OUT = "P_STATUS";
    private static final String PARAM_P_MESSAGE_OUT = "P_MESSAGE";
    private static final String PARAM_P_PROCESSED_AT_OUT = "P_PROCESSED_AT";

    private final SimpleJdbcCall jdbcCall;

    public PaymentRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("process_payment")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        // IN parameters
                        new SqlParameter(PARAM_P_ACCOUNT_ID_IN, Types.VARCHAR),
                        new SqlParameter(PARAM_P_AMOUNT_IN, Types.NUMERIC),
                        new SqlParameter(PARAM_P_CURRENCY_IN, Types.VARCHAR),
                        new SqlParameter(PARAM_P_MERCHANT_ID_IN, Types.VARCHAR),
                        new SqlParameter(PARAM_P_IDEMPOTENCY_KEY_IN, Types.VARCHAR),
                        // OUT parameters
                        new SqlOutParameter(PARAM_P_TRANSACTION_ID_OUT, Types.VARCHAR),
                        new SqlOutParameter(PARAM_P_STATUS_OUT, Types.VARCHAR),
                        new SqlOutParameter(PARAM_P_MESSAGE_OUT, Types.VARCHAR),
                        new SqlOutParameter(PARAM_P_PROCESSED_AT_OUT, Types.TIMESTAMP)
                );
    }

    public PaymentResponse callProcessPayment(PaymentRequest request) {

        // Build the input parameters — key must match the IN param name in the procedure
        Map<String, Object> inParams = Map.of(
                PARAM_P_ACCOUNT_ID_IN, request.getAccountId(),
                PARAM_P_AMOUNT_IN, request.getAmount(),
                PARAM_P_CURRENCY_IN, request.getCurrency(),
                PARAM_P_MERCHANT_ID_IN, request.getMerchantId(),
                PARAM_P_IDEMPOTENCY_KEY_IN, request.getIdempotencyKey()
        );

        // Execute the stored procedure
        Map<String, Object> result = new java.util.HashMap<>();
        try {
            result = jdbcCall.execute(inParams);
        } catch (DataAccessException e) {
            throw new IllegalStateException("Failed to execute stored procedure: process_payment" + e.getMessage(), e);
        }

        Object p_transaction_id = result.get(PARAM_P_TRANSACTION_ID_OUT);
        Object p_status = result.get(PARAM_P_STATUS_OUT);
        Object p_message = result.get(PARAM_P_MESSAGE_OUT);
        Timestamp ts = (Timestamp) result.get(PARAM_P_PROCESSED_AT_OUT);
        LocalDateTime p_processed_at = (ts != null) ? ts.toLocalDateTime() : LocalDateTime.now();


        if (p_transaction_id == null) {
            throw new IllegalStateException("Stored procedure get_date did not return OUT parameter: "
                    + PARAM_P_TRANSACTION_ID_OUT
                    + ". Returned keys: " + result.keySet());
        }


        // Map the OUT parameter to the response — key must match the OUT param name
        return PaymentResponse.builder()
                .transactionId(p_transaction_id.toString())
                .status(p_status.toString())
                .accountId(request.getAccountId())
                .amount(request.getAmount())
                .currency(request.getCurrency())
                .merchantId(request.getMerchantId())
                .message(p_message.toString())
                .processedAt(p_processed_at)
                .build();
    }

}