-- ==========================================
-- 03. TRANSFORM DATA
-- ==========================================


-- ==========================================
-- 1. CLEAN PROMOTION DATA
-- ==========================================

-- The raw promotion file can contain multiple
-- records for the same product, store and week.
-- We combine them into one clean record.

INSERT INTO retail.promotion_support (
    product_id,
    store_id,
    week_no,
    display_present,
    mailer_present
)
SELECT
    product_id,
    store_id,
    week_no,

    -- If any record has a display promotion,
    -- mark display as present.
    MAX(
        CASE
            WHEN display <> '0' THEN 1
            ELSE 0
        END
    ) AS display_present,

    -- If any record has a mailer promotion,
    -- mark mailer as present.
    MAX(
        CASE
            WHEN mailer <> '0' THEN 1
            ELSE 0
        END
    ) AS mailer_present

FROM retail.causal_raw

GROUP BY
    product_id,
    store_id,
    week_no;


-- Raw staging data is no longer needed
-- after the cleaned promotion table is created.
DROP TABLE retail.causal_raw;


-- ==========================================
-- 2. CREATE WEEKLY SALES TABLE
-- ==========================================

-- Convert transaction-level data into
-- Product + Store + Week level data.
-- This makes later analysis easier and faster.

CREATE TABLE retail.weekly_sales AS
SELECT
    product_id,
    store_id,
    week_no,

    -- Total sales value for the week
    SUM(sales_value) AS sales,

    -- Total number of units sold
    SUM(quantity) AS units,

    -- Number of unique baskets/transactions
    COUNT(DISTINCT basket_id) AS transactions,

    -- Total retail discount
    SUM(retail_disc) AS retail_discount,

    -- Total coupon discount
    SUM(coupon_disc) AS coupon_discount

FROM retail.transactions

GROUP BY
    product_id,
    store_id,
    week_no;


-- ==========================================
-- 3. CREATE ANALYSIS-READY VIEW
-- ==========================================

-- Combine weekly sales, product information
-- and promotion information into one view.
-- This is the main dataset used for analysis.

CREATE VIEW retail.promotion_analysis AS
SELECT
    w.product_id,
    w.store_id,
    w.week_no,
    p.department,
    w.sales,
    w.units,
    w.transactions,
    w.retail_discount,
    w.coupon_discount,
    ps.display_present,
    ps.mailer_present,

    -- Convert promotion flags into a
    -- simple business-friendly category.
    CASE
        WHEN ps.product_id IS NULL THEN 'Unknown'

        WHEN ps.display_present = 1
         AND ps.mailer_present = 1
            THEN 'Display + Mailer'

        WHEN ps.display_present = 1
            THEN 'Display Only'

        WHEN ps.mailer_present = 1
            THEN 'Mailer Only'

        ELSE 'Neither'
    END AS promotion_type

FROM retail.weekly_sales AS w

LEFT JOIN retail.promotion_support AS ps
    ON w.product_id = ps.product_id
    AND w.store_id = ps.store_id
    AND w.week_no = ps.week_no

LEFT JOIN retail.products AS p
    ON w.product_id = p.product_id;