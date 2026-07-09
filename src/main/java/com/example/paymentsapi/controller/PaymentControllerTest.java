package com.example.paymentsapi.controller;

import com.example.paymentsapi.model.PaymentRequest;
import com.example.paymentsapi.model.PaymentResponse;
import com.example.paymentsapi.service.PaymentService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.hamcrest.Matchers;
import static org.assertj.core.api.Assertions.assertThat;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.testng.AbstractTestNGSpringContextTests;
import org.springframework.test.web.servlet.MockMvc;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import static org.mockito.ArgumentMatchers.any;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(PaymentController.class)
public class PaymentControllerTest extends AbstractTestNGSpringContextTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private PaymentService paymentService;

    @BeforeMethod
    public void resetMocks() {
        Mockito.reset(paymentService);
    }

    @Test(description = "Should return approved when a valid payload is provided")
    public void shouldReturnApprovedWhenValidPayloadIsProvided() throws Exception {

        // Arrange
        PaymentRequest request = new PaymentRequest();
        request.setAccountId("1234567890");
        request.setAmount(new java.math.BigDecimal("100.00"));
        request.setCurrency("USD");
        request.setMerchantId("Alexandre");
        request.setIdempotencyKey("1234567890");

        /*
        PaymentResponse response = PaymentResponse.builder()
                .merchantId("Alexandre")
                .message("2024-06-21")
                .build();

        Mockito.when(paymentService.processRequest(any(PaymentRequest.class)))
               .thenReturn(CompletableFuture.completedFuture(response));
        */

        // Act + Assert
        String responseBody = mockMvc.perform(post("/api/payment/get-date")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        PaymentResponse response = objectMapper.readValue(responseBody, PaymentResponse.class);
        assertThat(response.getStatus()).isEqualTo("APPROVED");
    }

    @Test(description = "Should return 400 when name is blank")
    public void shouldReturn400WhenNameIsBlank() throws Exception {

        // Arrange
        PaymentRequest request = new PaymentRequest();
        request.setAccountId("1234567890");
        request.setAmount(new java.math.BigDecimal("100.00"));
        request.setCurrency("USD");
        request.setMerchantId("");
        request.setIdempotencyKey("1234567890");

        // Act + Assert
        mockMvc.perform(post("/api/payment/get-date")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test(description = "Should return 400 when request body is missing")
    public void shouldReturn400WhenBodyIsMissing() throws Exception {

        // Act + Assert
        mockMvc.perform(post("/api/payment/get-date")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());
    }

}