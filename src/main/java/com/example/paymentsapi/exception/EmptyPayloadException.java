package com.example.paymentsapi.exception;

public class EmptyPayloadException extends RuntimeException {

    public EmptyPayloadException() {
        super("Request body is missing or empty. A valid JSON payload is required.");
    }

}