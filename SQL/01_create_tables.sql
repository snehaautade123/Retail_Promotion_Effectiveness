-- ==========================================
-- 01. DATABASE SETUP
-- ==========================================

-- Create the project schema
CREATE SCHEMA retail;


-- ==========================================
-- 02. MAIN TABLES
-- ==========================================

-- Store transaction-level sales data
CREATE TABLE retail.transactions (
    household_key BIGINT,
    basket_id BIGINT,
    day INTEGER,
    product_id BIGINT,
    quantity INTEGER,
    sales_value NUMERIC(12,2),
    store_id INTEGER,
    retail_disc NUMERIC(12,2),
    trans_time INTEGER,
    week_no INTEGER,
    coupon_disc NUMERIC(12,2),
    coupon_match_disc NUMERIC(12,2)
);


-- Store product information
CREATE TABLE retail.products (
    product_id BIGINT,
    manufacturer INTEGER,
    department VARCHAR(100),
    brand VARCHAR(100),
    commodity_desc VARCHAR(255),
    sub_commodity_desc VARCHAR(255),
    curr_size_of_product VARCHAR(100)
);


-- Store cleaned promotion-support information
CREATE TABLE retail.promotion_support (
    product_id BIGINT,
    store_id INTEGER,
    week_no INTEGER,
    display_present INTEGER,
    mailer_present INTEGER
);


-- ==========================================
-- 03. CAMPAIGN AND HOUSEHOLD TABLES
-- ==========================================

-- Store campaign descriptions and dates
CREATE TABLE retail.campaigns (
    description VARCHAR(255),
    campaign INTEGER,
    start_day INTEGER,
    end_day INTEGER
);


-- Store campaign-household relationships
CREATE TABLE retail.campaign_households (
    description VARCHAR(255),
    household_key BIGINT,
    campaign INTEGER
);


-- Store household demographic information
CREATE TABLE retail.households (
    classification_1 VARCHAR(100),
    classification_2 VARCHAR(100),
    classification_3 VARCHAR(100),
    homeowner_desc VARCHAR(100),
    classification_5 VARCHAR(100),
    classification_4 VARCHAR(100),
    kid_category_desc VARCHAR(100),
    household_key BIGINT
);


-- ==========================================
-- 04. COUPON TABLES
-- ==========================================

-- Store coupon and product relationships
CREATE TABLE retail.coupons (
    coupon_upc BIGINT,
    product_id BIGINT,
    campaign INTEGER
);


-- Store actual coupon redemptions
CREATE TABLE retail.coupon_redemptions (
    household_key BIGINT,
    day INTEGER,
    coupon_upc BIGINT,
    campaign INTEGER
);


-- ==========================================
-- 05. STAGING TABLE
-- ==========================================

-- Temporary table used while processing causal_data.csv
CREATE TABLE retail.causal_raw (
    product_id BIGINT,
    store_id INTEGER,
    week_no INTEGER,
    display VARCHAR(10),
    mailer VARCHAR(10)
);


-- ==========================================
-- 06. KEYS AND PERFORMANCE
-- ==========================================

-- Product + Store + Week uniquely identifies
-- a promotion-support record.
ALTER TABLE retail.promotion_support
ADD CONSTRAINT promotion_support_pk
PRIMARY KEY (product_id, store_id, week_no);


-- Product ID uniquely identifies a product.
ALTER TABLE retail.products
ADD PRIMARY KEY (product_id);


-- Index used for Product + Store + Week joins
-- with the transaction data.
CREATE INDEX idx_transactions_product_store_week
ON retail.transactions (product_id, store_id, week_no);