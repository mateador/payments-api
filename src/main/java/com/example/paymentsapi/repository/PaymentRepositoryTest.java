package com.example.paymentsapi.repository;

import com.example.paymentsapi.model.PaymentRequest;
import com.example.paymentsapi.model.PaymentResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.testng.AbstractTestNGSpringContextTests;
import org.testng.annotations.Test;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
public class PaymentRepositoryTest extends AbstractTestNGSpringContextTests {

    @Autowired
    private PaymentRepository paymentRepository;

    @Test(description = "Should return a valid date from the stored procedure")
    public void shouldReturnDateFromStoredProcedure() {

        // Arrange
        PaymentRequest request = new PaymentRequest();
        request.setAccountId("1234567890");
        request.setAmount(new java.math.BigDecimal("100.00"));
        request.setCurrency("USD");
        request.setMerchantId("Alexandre");
        request.setIdempotencyKey("1234567890");

        // Act
        PaymentResponse response = paymentRepository.callGetDate(request);

        // Assert
        assertThat(response).isNotNull();
        assertThat(response.getMerchantId()).isEqualTo("Alexandre");
        assertThat(response.getMessage())
                .isNotBlank()
                .matches("\\d{4}-\\d{2}-\\d{2}");
    }

}