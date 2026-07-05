-- ============================================================
-- PAYMENT API — FULL DATABASE SCRIPT
-- Oracle Database Free
-- Run order: DDL first, then data load
-- ============================================================

-- ============================================================
-- PAYMENT API DATABASE STRUCTURE
-- Oracle Database Free
-- ============================================================

-- ============================================================
-- 1. MERCHANTS
--    Stores the 100 merchants the API will validate against
-- ============================================================
CREATE TABLE merchants (
    merchant_id      VARCHAR2(20)    NOT NULL,
    merchant_name    VARCHAR2(100)   NOT NULL,
    status           VARCHAR2(10)    DEFAULT 'ACTIVE' NOT NULL,
    currency         VARCHAR2(3)     DEFAULT 'GBP'    NOT NULL,
    created_at       TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at       TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_merchants         PRIMARY KEY (merchant_id),
    CONSTRAINT ck_merchant_status   CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    CONSTRAINT ck_merchant_currency CHECK (currency IN ('GBP', 'USD', 'EUR', 'BRL'))
);

-- ============================================================
-- 2. ACCOUNTS
--    Stores the accounts that submit payment requests
-- ============================================================
CREATE TABLE accounts (
    account_id       VARCHAR2(20)    NOT NULL,
    merchant_id      VARCHAR2(20)    NOT NULL,
    account_name     VARCHAR2(100)   NOT NULL,
    status           VARCHAR2(10)    DEFAULT 'ACTIVE' NOT NULL,
    created_at       TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_accounts          PRIMARY KEY (account_id),
    CONSTRAINT fk_accounts_merchant FOREIGN KEY (merchant_id)
        REFERENCES merchants (merchant_id),
    CONSTRAINT ck_account_status    CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

-- ============================================================
-- 3. PAYMENT_REQUESTS
--    Maps to the inbound JSON payload
--    One row per unique idempotency key (supports dedup)
-- ============================================================
CREATE TABLE payment_requests (
    idempotency_key  VARCHAR2(100)   NOT NULL,
    account_id       VARCHAR2(20)    NOT NULL,
    merchant_id      VARCHAR2(20)    NOT NULL,
    amount           NUMBER(15,2)    NOT NULL,
    currency         VARCHAR2(3)     NOT NULL,
    status           VARCHAR2(15)    DEFAULT 'PENDING' NOT NULL,
    created_at       TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_payment_requests        PRIMARY KEY (idempotency_key),
    CONSTRAINT fk_preq_account            FOREIGN KEY (account_id)
        REFERENCES accounts (account_id),
    CONSTRAINT fk_preq_merchant           FOREIGN KEY (merchant_id)
        REFERENCES merchants (merchant_id),
    CONSTRAINT ck_preq_amount             CHECK (amount > 0),
    CONSTRAINT ck_preq_currency           CHECK (currency IN ('GBP', 'USD', 'EUR', 'BRL')),
    CONSTRAINT ck_preq_status             CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETE', 'FAILED'))
);

-- ============================================================
-- 4. TRANSACTIONS
--    Maps to the outbound JSON response
--    One row per processed payment result
-- ============================================================
CREATE TABLE transactions (
    transaction_id   VARCHAR2(30)    NOT NULL,
    idempotency_key  VARCHAR2(100)   NOT NULL,
    account_id       VARCHAR2(20)    NOT NULL,
    merchant_id      VARCHAR2(20)    NOT NULL,
    amount           NUMBER(15,2)    NOT NULL,
    currency         VARCHAR2(3)     NOT NULL,
    status           VARCHAR2(10)    NOT NULL,
    message          VARCHAR2(255)   NOT NULL,
    processed_at     TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at       TIMESTAMP       DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_transactions           PRIMARY KEY (transaction_id),
    CONSTRAINT uq_txn_idempotency_key    UNIQUE (idempotency_key),
    CONSTRAINT fk_txn_request            FOREIGN KEY (idempotency_key)
        REFERENCES payment_requests (idempotency_key),
    CONSTRAINT fk_txn_account            FOREIGN KEY (account_id)
        REFERENCES accounts (account_id),
    CONSTRAINT fk_txn_merchant           FOREIGN KEY (merchant_id)
        REFERENCES merchants (merchant_id),
    CONSTRAINT ck_txn_amount             CHECK (amount > 0),
    CONSTRAINT ck_txn_currency           CHECK (currency IN ('GBP', 'USD', 'EUR', 'BRL')),
    CONSTRAINT ck_txn_status             CHECK (status IN ('APPROVED', 'DECLINED', 'ERROR'))
);

-- ============================================================
-- SEQUENCES
--    transaction_id is system-generated in the format
--    TXN-YYYYMMDD-NNN to match the API response example
-- ============================================================
CREATE SEQUENCE seq_transaction_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- ============================================================
-- INDEXES
-- ============================================================
-- Speed up lookups by account within payment_requests
CREATE INDEX idx_preq_account_id   ON payment_requests (account_id);
CREATE INDEX idx_preq_merchant_id  ON payment_requests (merchant_id);
CREATE INDEX idx_preq_status       ON payment_requests (status);

-- Speed up lookups by account and merchant in transactions
CREATE INDEX idx_txn_account_id    ON transactions (account_id);
CREATE INDEX idx_txn_merchant_id   ON transactions (merchant_id);
CREATE INDEX idx_txn_status        ON transactions (status);
CREATE INDEX idx_txn_processed_at  ON transactions (processed_at);

-- ============================================================
-- END DDL
-- ============================================================

-- ============================================================
-- DATA LOAD
-- ============================================================

-- ============================================================
-- MERCHANTS: 100 rows
-- ============================================================
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-01', 'TechPay Solutions', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-02', 'SwiftTrade Ltd', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-03', 'NovaCommerce', 'SUSPENDED', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-04', 'BlueSky Payments', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-05', 'RedLine Retail', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-06', 'Apex Merchants', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-07', 'ClearPath Finance', 'SUSPENDED', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-08', 'Vertex Commerce', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-09', 'Pinnacle Stores', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-10', 'Horizon Digital', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-11', 'Crestview Trading', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-12', 'Silvergate Shop', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-13', 'Ember Retail Co', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-14', 'Falcon Payments', 'INACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-15', 'Orion Merchants', 'INACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-16', 'Summit Bazaar', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-17', 'Atlas Commerce', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-18', 'Pulse Retail', 'INACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-19', 'Vega Payments Ltd', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-20', 'Titan Trade', 'INACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-21', 'Zenith Shop', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-22', 'Solaris Merchants', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-23', 'Aurora Digital', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-24', 'Eclipse Commerce', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-25', 'Catalyst Retail', 'INACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-26', 'Nexus Payments', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-27', 'Spectrum Trading', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-28', 'Quantum Shop', 'INACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-29', 'Onyx Commerce', 'INACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-30', 'Prism Retail Ltd', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-31', 'Matrix Merchants', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-32', 'Helix Pay Co', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-33', 'Cobalt Commerce', 'SUSPENDED', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-34', 'Amber Retail', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-35', 'Granite Trade', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-36', 'Sapphire Payments', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-37', 'Ruby Commerce Ltd', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-38', 'Jade Merchants', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-39', 'Pearl Trading Co', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-40', 'Coral Retail', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-41', 'Indigo Digital Pay', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-42', 'Aqua Commerce', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-43', 'Crimson Retail', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-44', 'Ivory Merchants', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-45', 'Ebony Trading Co', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-46', 'Teal Payments', 'SUSPENDED', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-47', 'Sienna Shop Ltd', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-48', 'Russet Commerce', 'INACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-49', 'Ochre Retail Co', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-50', 'Fern Merchants', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-51', 'Cedar Pay Solutions', 'SUSPENDED', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-52', 'Birch Commerce', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-53', 'Maple Trade Ltd', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-54', 'Oakwood Payments', 'SUSPENDED', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-55', 'Willow Retail Co', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-56', 'Elmwood Shop', 'SUSPENDED', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-57', 'Ashwood Merchants', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-58', 'Chestnut Trading', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-59', 'Hazel Pay Ltd', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-60', 'Walnut Commerce', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-61', 'Pine Retail Co', 'INACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-62', 'Spruce Payments', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-63', 'Fir Tree Trading', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-64', 'Beech Commerce', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-65', 'Magnolia Shop Ltd', 'INACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-66', 'Jasmine Merchants', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-67', 'Lotus Payments Co', 'SUSPENDED', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-68', 'Dahlia Retail', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-69', 'Iris Commerce Ltd', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-70', 'Poppy Trading', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-71', 'Violet Pay Solutions', 'SUSPENDED', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-72', 'Marigold Shop', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-73', 'Zinnia Merchants', 'SUSPENDED', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-74', 'Aster Commerce', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-75', 'Clover Retail Ltd', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-76', 'Thistle Payments', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-77', 'Heather Trading', 'SUSPENDED', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-78', 'Sorrel Commerce', 'INACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-79', 'Basil Merchants Ltd', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-80', 'Sage Pay Co', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-81', 'Rosemary Retail', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-82', 'Thyme Commerce', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-83', 'Mint Payments Ltd', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-84', 'Parsley Shop', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-85', 'Cilantro Merchants', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-86', 'Dill Commerce Co', 'SUSPENDED', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-87', 'Tarragon Retail', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-88', 'Fennel Trading', 'INACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-89', 'Anise Pay Solutions', 'ACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-90', 'Cumin Commerce', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-91', 'Caraway Merchants', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-92', 'Paprika Shop', 'INACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-93', 'Saffron Trading Co', 'INACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-94', 'Turmeric Retail', 'ACTIVE', 'USD');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-95', 'Ginger Payments Ltd', 'SUSPENDED', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-96', 'Cardamom Shop', 'INACTIVE', 'GBP');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-97', 'Cinnamon Merchants', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-98', 'Clove Commerce', 'ACTIVE', 'BRL');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-99', 'Nutmeg Retail Co', 'ACTIVE', 'EUR');
INSERT INTO merchants (merchant_id, merchant_name, status, currency) VALUES ('MERCH-100', 'Pepper Payments', 'SUSPENDED', 'BRL');

-- ============================================================
-- ACCOUNTS: one account per merchant (ACC-001 to ACC-100)
-- ============================================================
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-001', 'MERCH-01', 'TechPay Solutions - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-002', 'MERCH-02', 'SwiftTrade Ltd - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-003', 'MERCH-03', 'NovaCommerce - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-004', 'MERCH-04', 'BlueSky Payments - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-005', 'MERCH-05', 'RedLine Retail - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-006', 'MERCH-06', 'Apex Merchants - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-007', 'MERCH-07', 'ClearPath Finance - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-008', 'MERCH-08', 'Vertex Commerce - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-009', 'MERCH-09', 'Pinnacle Stores - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-010', 'MERCH-10', 'Horizon Digital - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-011', 'MERCH-11', 'Crestview Trading - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-012', 'MERCH-12', 'Silvergate Shop - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-013', 'MERCH-13', 'Ember Retail Co - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-014', 'MERCH-14', 'Falcon Payments - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-015', 'MERCH-15', 'Orion Merchants - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-016', 'MERCH-16', 'Summit Bazaar - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-017', 'MERCH-17', 'Atlas Commerce - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-018', 'MERCH-18', 'Pulse Retail - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-019', 'MERCH-19', 'Vega Payments Ltd - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-020', 'MERCH-20', 'Titan Trade - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-021', 'MERCH-21', 'Zenith Shop - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-022', 'MERCH-22', 'Solaris Merchants - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-023', 'MERCH-23', 'Aurora Digital - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-024', 'MERCH-24', 'Eclipse Commerce - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-025', 'MERCH-25', 'Catalyst Retail - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-026', 'MERCH-26', 'Nexus Payments - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-027', 'MERCH-27', 'Spectrum Trading - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-028', 'MERCH-28', 'Quantum Shop - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-029', 'MERCH-29', 'Onyx Commerce - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-030', 'MERCH-30', 'Prism Retail Ltd - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-031', 'MERCH-31', 'Matrix Merchants - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-032', 'MERCH-32', 'Helix Pay Co - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-033', 'MERCH-33', 'Cobalt Commerce - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-034', 'MERCH-34', 'Amber Retail - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-035', 'MERCH-35', 'Granite Trade - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-036', 'MERCH-36', 'Sapphire Payments - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-037', 'MERCH-37', 'Ruby Commerce Ltd - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-038', 'MERCH-38', 'Jade Merchants - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-039', 'MERCH-39', 'Pearl Trading Co - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-040', 'MERCH-40', 'Coral Retail - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-041', 'MERCH-41', 'Indigo Digital Pay - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-042', 'MERCH-42', 'Aqua Commerce - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-043', 'MERCH-43', 'Crimson Retail - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-044', 'MERCH-44', 'Ivory Merchants - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-045', 'MERCH-45', 'Ebony Trading Co - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-046', 'MERCH-46', 'Teal Payments - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-047', 'MERCH-47', 'Sienna Shop Ltd - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-048', 'MERCH-48', 'Russet Commerce - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-049', 'MERCH-49', 'Ochre Retail Co - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-050', 'MERCH-50', 'Fern Merchants - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-051', 'MERCH-51', 'Cedar Pay Solutions - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-052', 'MERCH-52', 'Birch Commerce - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-053', 'MERCH-53', 'Maple Trade Ltd - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-054', 'MERCH-54', 'Oakwood Payments - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-055', 'MERCH-55', 'Willow Retail Co - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-056', 'MERCH-56', 'Elmwood Shop - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-057', 'MERCH-57', 'Ashwood Merchants - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-058', 'MERCH-58', 'Chestnut Trading - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-059', 'MERCH-59', 'Hazel Pay Ltd - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-060', 'MERCH-60', 'Walnut Commerce - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-061', 'MERCH-61', 'Pine Retail Co - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-062', 'MERCH-62', 'Spruce Payments - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-063', 'MERCH-63', 'Fir Tree Trading - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-064', 'MERCH-64', 'Beech Commerce - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-065', 'MERCH-65', 'Magnolia Shop Ltd - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-066', 'MERCH-66', 'Jasmine Merchants - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-067', 'MERCH-67', 'Lotus Payments Co - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-068', 'MERCH-68', 'Dahlia Retail - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-069', 'MERCH-69', 'Iris Commerce Ltd - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-070', 'MERCH-70', 'Poppy Trading - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-071', 'MERCH-71', 'Violet Pay Solutions - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-072', 'MERCH-72', 'Marigold Shop - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-073', 'MERCH-73', 'Zinnia Merchants - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-074', 'MERCH-74', 'Aster Commerce - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-075', 'MERCH-75', 'Clover Retail Ltd - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-076', 'MERCH-76', 'Thistle Payments - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-077', 'MERCH-77', 'Heather Trading - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-078', 'MERCH-78', 'Sorrel Commerce - Trading Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-079', 'MERCH-79', 'Basil Merchants Ltd - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-080', 'MERCH-80', 'Sage Pay Co - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-081', 'MERCH-81', 'Rosemary Retail - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-082', 'MERCH-82', 'Thyme Commerce - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-083', 'MERCH-83', 'Mint Payments Ltd - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-084', 'MERCH-84', 'Parsley Shop - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-085', 'MERCH-85', 'Cilantro Merchants - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-086', 'MERCH-86', 'Dill Commerce Co - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-087', 'MERCH-87', 'Tarragon Retail - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-088', 'MERCH-88', 'Fennel Trading - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-089', 'MERCH-89', 'Anise Pay Solutions - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-090', 'MERCH-90', 'Cumin Commerce - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-091', 'MERCH-91', 'Caraway Merchants - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-092', 'MERCH-92', 'Paprika Shop - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-093', 'MERCH-93', 'Saffron Trading Co - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-094', 'MERCH-94', 'Turmeric Retail - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-095', 'MERCH-95', 'Ginger Payments Ltd - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-096', 'MERCH-96', 'Cardamom Shop - Main Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-097', 'MERCH-97', 'Cinnamon Merchants - Online Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-098', 'MERCH-98', 'Clove Commerce - Retail Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-099', 'MERCH-99', 'Nutmeg Retail Co - Primary Account');
INSERT INTO accounts (account_id, merchant_id, account_name) VALUES ('ACC-100', 'MERCH-100', 'Pepper Payments - Trading Account');

COMMIT;

-- ============================================================
-- VERIFICATION QUERIES
-- Run these after executing the script to confirm the load
-- ============================================================

-- Count rows loaded
SELECT 'MERCHANTS' AS table_name, COUNT(*) AS row_count FROM merchants
UNION ALL
SELECT 'ACCOUNTS',                COUNT(*)               FROM accounts;

-- Sample merchant with its account
SELECT m.merchant_id, m.merchant_name, m.status, m.currency,
       a.account_id, a.account_name
FROM   merchants m
JOIN   accounts  a ON a.merchant_id = m.merchant_id
WHERE  m.merchant_id = 'MERCH-01';

-- ============================================================
-- EXAMPLE: simulate the payment JSON flow manually
-- ============================================================

-- 1. Insert the inbound payment request (maps to the request JSON)
INSERT INTO payment_requests (
    idempotency_key,
    account_id,
    merchant_id,
    amount,
    currency,
    status
) VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'ACC-001',
    'MERCH-01',
    150.00,
    'GBP',
    'PROCESSING'
);

-- 2. Insert the transaction result (maps to the response JSON)
--    transaction_id generated using sequence + today's date
INSERT INTO transactions (
    transaction_id,
    idempotency_key,
    account_id,
    merchant_id,
    amount,
    currency,
    status,
    message,
    processed_at
) VALUES (
    'TXN-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' ||
        LPAD(seq_transaction_id.NEXTVAL, 3, '0'),
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'ACC-001',
    'MERCH-01',
    150.00,
    'GBP',
    'APPROVED',
    'Payment processed successfully',
    SYSTIMESTAMP
);

-- 3. Mark the request as complete
UPDATE payment_requests
SET    status     = 'COMPLETE',
       updated_at = SYSTIMESTAMP
WHERE  idempotency_key = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

COMMIT;

-- 4. Read back the transaction (matches the response JSON shape)
SELECT transaction_id,
       status,
       account_id,
       amount,
       currency,
       merchant_id,
       message,
       TO_CHAR(processed_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS processed_at
FROM   transactions
WHERE  idempotency_key = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
/
