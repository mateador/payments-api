CREATE OR REPLACE PROCEDURE process_payment (
    -- IN parameters
    p_account_id        IN  VARCHAR2,
    p_amount            IN  NUMBER,
    p_currency          IN  VARCHAR2,
    p_merchant_id       IN  VARCHAR2,
    p_idempotency_key   IN  VARCHAR2,

    -- OUT parameters
    p_transaction_id    OUT VARCHAR2,
    p_status            OUT VARCHAR2,
    p_message           OUT VARCHAR2,
    p_processed_at      OUT TIMESTAMP    -- changed from VARCHAR2
)
    IS
BEGIN

    p_transaction_id := 'TXN-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-001';
    p_status         := 'APPROVED';
    p_message        := 'Payment processed successfully';
    p_processed_at   := SYSTIMESTAMP;   -- no TO_CHAR, pure TIMESTAMP

END process_payment;
/