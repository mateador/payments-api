package com.example.paymentsapi.exception;

public class MerchantNotFoundException extends RuntimeException {

    public MerchantNotFoundException(String merchantId) {
        super("Merchant not found or inactive: " + merchantId);
    }

}