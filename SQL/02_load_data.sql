-- ==========================================
-- 02. LOAD DATA INTO POSTGRESQL
-- ==========================================

-- Load transaction-level sales data
\copy retail.transactions FROM 'Data/transaction_data.csv' WITH (FORMAT csv, HEADER true)


-- Load product information
\copy retail.products FROM 'Data/product.csv' WITH (FORMAT csv, HEADER true)


-- Load raw promotion-support data
-- This data will be cleaned in the transformation step.
\copy retail.causal_raw FROM 'Data/causal_data.csv' WITH (FORMAT csv, HEADER true)


-- Load campaign descriptions
\copy retail.campaigns FROM 'Data/campaign_desc.csv' WITH (FORMAT csv, HEADER true)


-- Load campaign-household relationships
\copy retail.campaign_households FROM 'Data/campaign_table.csv' WITH (FORMAT csv, HEADER true)


-- Load household demographic information
\copy retail.households FROM 'Data/hh_demographic.csv' WITH (FORMAT csv, HEADER true)


-- Load coupon information
\copy retail.coupons FROM 'Data/coupon.csv' WITH (FORMAT csv, HEADER true)


-- Load actual coupon redemption records
\copy retail.coupon_redemptions FROM 'Data/coupon_redempt.csv' WITH (FORMAT csv, HEADER true)