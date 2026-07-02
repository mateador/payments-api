package com.example.paymentsapi.service;

import com.example.paymentsapi.model.PaymentRequest;
import com.example.paymentsapi.model.PaymentResponse;
import com.example.paymentsapi.repository.PaymentRepository;
import org.springframework.stereotype.Service;

@Service
public class PaymentService {

    private final PaymentRepository paymentRepository;

    public PaymentService(PaymentRepository paymentRepository) {
        this.paymentRepository = paymentRepository;
    }

    public PaymentResponse processRequest(PaymentRequest request) {
        return paymentRepository.callGetDate(request);
    }

}