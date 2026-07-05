package com.example.paymentsapi.service;

import com.example.paymentsapi.exception.MerchantNotFoundException;
import com.example.paymentsapi.model.PaymentRequest;
import com.example.paymentsapi.model.PaymentResponse;
import com.example.paymentsapi.repository.MerchantRepository;
import com.example.paymentsapi.repository.PaymentRepository;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;

@Service
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final MerchantRepository merchantRepository;

    public PaymentService(PaymentRepository paymentRepository, MerchantRepository merchantRepository) {
        this.paymentRepository = paymentRepository;
        this.merchantRepository = merchantRepository;
    }

    @Async("paymentExecutor")
    public CompletableFuture<PaymentResponse> processRequest(PaymentRequest request) {

        // Validate merchant exists and is ACTIVE before touching payment flow
        if (!merchantRepository.existsAndActive(request.getMerchantId())) {
            throw new MerchantNotFoundException(request.getMerchantId());
        }

        PaymentResponse response = paymentRepository.callProcessPayment(request);
        return CompletableFuture.completedFuture(response);
    }

}