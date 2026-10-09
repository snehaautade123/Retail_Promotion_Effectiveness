-- ==========================================
-- BUSINESS QUESTION 1
-- How do sales differ across promotional-support types?
-- ==========================================

SELECT
    promotion_type,
    COUNT(*) AS weeks,
    ROUND(AVG(sales), 2) AS average_sales,
    ROUND(AVG(units), 2) AS average_units
FROM retail.promotion_analysis

-- Promotion status is unknown when promotion data
-- is not available for that product-store-week.
WHERE promotion_type <> 'Unknown'

GROUP BY promotion_type
ORDER BY average_sales DESC;

-- BUSINESS QUESTION 2
-- Among comparable products, how does average sales compare
-- across the three promotion-support types?
--
-- Each product gets equal importance in the final comparison.

WITH product_promotion AS (

    -- First calculate the average sales for each product
    -- under each promotion type.
    SELECT
        product_id,
        promotion_type,
        COUNT(*) AS weeks,
        AVG(sales) AS average_sales
    FROM retail.promotion_analysis
    WHERE promotion_type IN (
        'Display Only',
        'Mailer Only',
        'Display + Mailer'
    )
    GROUP BY
        product_id,
        promotion_type
),

comparable_products AS (

    -- Keep only products that have at least 2 weeks
    -- in all three promotion types.
    SELECT
        product_id
    FROM product_promotion
    GROUP BY product_id
    HAVING COUNT(*) FILTER (
        WHERE promotion_type = 'Display Only'
        AND weeks >= 2
    ) = 1
    AND COUNT(*) FILTER (
        WHERE promotion_type = 'Mailer Only'
        AND weeks >= 2
    ) = 1
    AND COUNT(*) FILTER (
        WHERE promotion_type = 'Display + Mailer'
        AND weeks >= 2
    ) = 1
)

SELECT
    pp.promotion_type,
    COUNT(*) AS comparable_products,

    -- Average of the product-level averages.
    -- This gives every product equal weight.
    ROUND(AVG(pp.average_sales), 3) AS average_product_sales

FROM product_promotion AS pp
JOIN comparable_products AS cp
    ON pp.product_id = cp.product_id

GROUP BY pp.promotion_type

ORDER BY average_product_sales DESC;

-- BUSINESS QUESTION 3
-- Within each department, which promotion type has the highest
-- observed average sales for the largest share of comparable products?

WITH product_promotion AS (

    -- First, calculate average sales for each product and promotion type.
    SELECT
        product_id,
        department,
        promotion_type,
        COUNT(*) AS weeks,
        AVG(sales) AS average_sales
    FROM retail.promotion_analysis
    WHERE promotion_type IN (
        'Display Only',
        'Mailer Only',
        'Display + Mailer'
    )
    GROUP BY
        product_id,
        department,
        promotion_type
),

comparable_products AS (

    -- Keep only products that have at least 2 weeks
    -- in all three promotion types.
    SELECT
        product_id
    FROM product_promotion
    GROUP BY product_id
    HAVING MIN(
        CASE
            WHEN promotion_type = 'Display Only' THEN weeks
        END
    ) >= 2
    AND MIN(
        CASE
            WHEN promotion_type = 'Mailer Only' THEN weeks
        END
    ) >= 2
    AND MIN(
        CASE
            WHEN promotion_type = 'Display + Mailer' THEN weeks
        END
    ) >= 2
),

product_comparison AS (

    -- Put the three promotion averages side by side for each product.
    SELECT
        pp.product_id,
        MAX(pp.department) AS department,

        MAX(CASE
            WHEN pp.promotion_type = 'Display Only'
            THEN pp.average_sales
        END) AS display_only_sales,

        MAX(CASE
            WHEN pp.promotion_type = 'Mailer Only'
            THEN pp.average_sales
        END) AS mailer_only_sales,

        MAX(CASE
            WHEN pp.promotion_type = 'Display + Mailer'
            THEN pp.average_sales
        END) AS display_mailer_sales

    FROM product_promotion AS pp
    JOIN comparable_products AS cp
        ON pp.product_id = cp.product_id
    GROUP BY pp.product_id
),

product_winner AS (

    -- Decide which promotion type has the highest observed sales
    -- for each comparable product. Ties are kept as "Tie".
    SELECT
        product_id,
        department,

        CASE
            WHEN display_only_sales > mailer_only_sales
             AND display_only_sales > display_mailer_sales
                THEN 'Display Only'

            WHEN mailer_only_sales > display_only_sales
             AND mailer_only_sales > display_mailer_sales
                THEN 'Mailer Only'

            WHEN display_mailer_sales > display_only_sales
             AND display_mailer_sales > mailer_only_sales
                THEN 'Display + Mailer'

            ELSE 'Tie'
        END AS highest_promotion

    FROM product_comparison
),

department_counts AS (

    -- Count comparable products in each department.
    SELECT
        department,
        COUNT(*) AS comparable_products
    FROM product_winner
    GROUP BY department
)

SELECT
    pw.department,
    dc.comparable_products,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE highest_promotion = 'Display Only'
        ) / COUNT(*),
        2
    ) AS display_only_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE highest_promotion = 'Mailer Only'
        ) / COUNT(*),
        2
    ) AS mailer_only_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE highest_promotion = 'Display + Mailer'
        ) / COUNT(*),
        2
    ) AS display_mailer_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE highest_promotion = 'Tie'
        ) / COUNT(*),
        2
    ) AS tie_pct

FROM product_winner AS pw
JOIN department_counts AS dc
    ON pw.department = dc.department

-- Avoid making conclusions from departments with very few products.
WHERE dc.comparable_products >= 30

GROUP BY
    pw.department,
    dc.comparable_products

ORDER BY
    dc.comparable_products DESC;

-- BUSINESS QUESTION 4
-- Among comparable products, how do sales and discount levels
-- differ across promotion-support types?

WITH comparable_products AS (

    -- Keep products that have at least 2 weeks
    -- in all three promotion types.
    SELECT
        product_id
    FROM retail.promotion_analysis
    WHERE promotion_type IN (
        'Display Only',
        'Mailer Only',
        'Display + Mailer'
    )
    GROUP BY product_id
    HAVING COUNT(*) FILTER (
        WHERE promotion_type = 'Display Only'
    ) >= 2
    AND COUNT(*) FILTER (
        WHERE promotion_type = 'Mailer Only'
    ) >= 2
    AND COUNT(*) FILTER (
        WHERE promotion_type = 'Display + Mailer'
    ) >= 2
)

SELECT
    promotion_type,
    COUNT(*) AS weeks,
    COUNT(DISTINCT product_id) AS comparable_products,
    ROUND(AVG(sales), 3) AS average_sales,
    ROUND(AVG(units), 3) AS average_units,

    -- Weighted retail discount per unit.
    -- Total discount is divided by total units sold.
    ROUND(
        -SUM(retail_discount) / NULLIF(SUM(units), 0),
        3
    ) AS weighted_retail_discount_per_unit,

    -- Weighted coupon discount per unit.
    ROUND(
        -SUM(coupon_discount) / NULLIF(SUM(units), 0),
        3
    ) AS weighted_coupon_discount_per_unit

FROM retail.promotion_analysis
WHERE product_id IN (
    SELECT product_id
    FROM comparable_products
)
AND promotion_type IN (
    'Display Only',
    'Mailer Only',
    'Display + Mailer'
)

GROUP BY promotion_type
ORDER BY average_sales DESC;

-- BUSINESS QUESTION 5
-- Across stores with sufficient observations, which promotion type
-- has the highest observed average sales?

WITH store_promotion AS (

    -- Calculate average sales for each store and promotion type.
    SELECT
        store_id,
        promotion_type,
        COUNT(*) AS weeks,
        AVG(sales) AS average_sales
    FROM retail.promotion_analysis
    WHERE promotion_type IN (
        'Display Only',
        'Mailer Only',
        'Display + Mailer'
    )
    GROUP BY
        store_id,
        promotion_type
),

comparable_stores AS (

    -- Keep only stores with at least 2 weeks
    -- in all three promotion types.
    SELECT
        store_id
    FROM store_promotion
    GROUP BY store_id
    HAVING MIN(
        CASE
            WHEN promotion_type = 'Display Only' THEN weeks
        END
    ) >= 2
    AND MIN(
        CASE
            WHEN promotion_type = 'Mailer Only' THEN weeks
        END
    ) >= 2
    AND MIN(
        CASE
            WHEN promotion_type = 'Display + Mailer' THEN weeks
        END
    ) >= 2
),

store_comparison AS (

    -- Put the three promotion averages side by side.
    SELECT
        sp.store_id,

        MAX(CASE
            WHEN sp.promotion_type = 'Display Only'
            THEN sp.average_sales
        END) AS display_only_sales,

        MAX(CASE
            WHEN sp.promotion_type = 'Mailer Only'
            THEN sp.average_sales
        END) AS mailer_only_sales,

        MAX(CASE
            WHEN sp.promotion_type = 'Display + Mailer'
            THEN sp.average_sales
        END) AS display_mailer_sales

    FROM store_promotion AS sp
    JOIN comparable_stores AS cs
        ON sp.store_id = cs.store_id
    GROUP BY sp.store_id
)

SELECT
    COUNT(*) AS comparable_stores,

    COUNT(*) FILTER (
        WHERE display_only_sales > mailer_only_sales
          AND display_only_sales > display_mailer_sales
    ) AS display_only_highest,

    COUNT(*) FILTER (
        WHERE mailer_only_sales > display_only_sales
          AND mailer_only_sales > display_mailer_sales
    ) AS mailer_only_highest,

    COUNT(*) FILTER (
        WHERE display_mailer_sales > display_only_sales
          AND display_mailer_sales > mailer_only_sales
    ) AS display_mailer_highest,

    COUNT(*) FILTER (
        WHERE display_only_sales = mailer_only_sales
           OR display_only_sales = display_mailer_sales
           OR mailer_only_sales = display_mailer_sales
    ) AS ties

FROM store_comparison;