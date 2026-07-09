package com.example.paymentsapi.controller;

import com.example.paymentsapi.model.PaymentRequest;
import com.example.paymentsapi.model.PaymentResponse;
import com.example.paymentsapi.service.PaymentService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/payment")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/get-date")
    public CompletableFuture<PaymentResponse> getDate(
            @Valid @RequestBody PaymentRequest request) {

        return paymentService.processRequest(request);
    }

}