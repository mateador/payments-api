package com.example.paymentsapi.repository;

import com.example.paymentsapi.model.PaymentRequest;
import com.example.paymentsapi.model.PaymentResponse;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.Types;
import java.util.Map;

@Repository
public class PaymentRepository {

    private static final String PARAM_NAME_IN = "name_in";
    private static final String PARAM_DATE_OUT = "DATE_OUT";

    private final SimpleJdbcCall jdbcCall;

    public PaymentRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("get_date")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter(PARAM_NAME_IN, Types.VARCHAR),
                        new SqlOutParameter(PARAM_DATE_OUT, Types.VARCHAR)
                );
    }

    public PaymentResponse callGetDate(PaymentRequest request) {

        // Build the input parameters — key must match the IN param name in the procedure
        Map<String, Object> inParams = Map.of(
                PARAM_NAME_IN, request.getMerchantId()
        );

        // Execute the stored procedure
        Map<String, Object> result = new java.util.HashMap<>();
        try {
            result = jdbcCall.execute(inParams);
        } catch (DataAccessException e) {
            throw new IllegalStateException("Failed to execute stored procedure: get_date" + e.getMessage(), e);
        }

        Object dateOut = result.get(PARAM_DATE_OUT);

        if (dateOut == null) {
            throw new IllegalStateException("Stored procedure get_date did not return OU parameter: "
                    + PARAM_DATE_OUT
                    + ". Returned keys: " + result.keySet());
        }


        // Map the OUT parameter to the response — key must match the OUT param name
        return PaymentResponse.builder()
                .merchantId(request.getMerchantId())
                .message(dateOut.toString())
                .build();
    }

}