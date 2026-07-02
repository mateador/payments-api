package com.example.paymentsapi.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentResponse {

    private String transactionId;
    private String status;           // e.g. APPROVED, DECLINED, ERROR
    private String accountId;
    private BigDecimal amount;
    private String currency;
    private String merchantId;
    private String message;          // human-readable result from the stored procedure
    private LocalDateTime processedAt;

}