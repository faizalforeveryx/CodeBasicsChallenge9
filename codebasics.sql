SELECT p.product_code, p.product_name, p.category, f.base_price, f.promo_type
FROM dim_products p
JOIN fact_events f ON p.product_code = f.product_code
JOIN dim_campaigns c ON f.campaign_id = c.campaign_id
WHERE f.base_price > 500
AND f.promo_type = 'BOGOF';

SELECT city, COUNT(store_id) AS store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

WITH RevenueBefore AS (
    SELECT
        fe.campaign_id,
        SUM(fe.base_price * fe.`quantity_sold(before_promo)`) / 1000000 AS total_revenue_before
    FROM
        fact_events fe
    GROUP BY
        fe.campaign_id
),
RevenueAfter AS (
    SELECT
        fe.campaign_id,
        SUM(fe.base_price * fe.`quantity_sold(after_promo)`) / 1000000 AS total_revenue_after
    FROM
        fact_events fe
    GROUP BY
        fe.campaign_id
)
SELECT
    dc.campaign_name,
    COALESCE(rb.total_revenue_before, 0) AS total_revenue_before_promotion_in_millions,
    COALESCE(ra.total_revenue_after, 0) AS total_revenue_after_promotion_in_millions
FROM
    dim_campaigns dc
LEFT JOIN
    RevenueBefore rb ON dc.campaign_id = rb.campaign_id
LEFT JOIN
    RevenueAfter ra ON dc.campaign_id = ra.campaign_id;

    
WITH CampaignSales AS (
    SELECT
        d.category,
        SUM(fe.`quantity_sold(after_promo)`) AS total_sold_after_promo,
        SUM(fe.`quantity_sold(before_promo)`) AS total_sold_before_promo
    FROM
        fact_events fe
    JOIN dim_products d ON fe.product_code = d.product_code
    JOIN dim_campaigns c ON fe.campaign_id = c.campaign_id
    WHERE
        c.campaign_name = 'Diwali' -- Filter for Diwali campaign
    GROUP BY
        d.category
),
CategoryISU AS (
    SELECT
        category,
        (total_sold_after_promo - total_sold_before_promo) / total_sold_before_promo * 100 AS isu_percentage
    FROM
        CampaignSales
)
SELECT
    category,
    isu_percentage,
    RANK() OVER (ORDER BY isu_percentage DESC) AS rank_order
FROM
    CategoryISU;
    
    
WITH ProductIR AS (
    SELECT
        d.product_name,
        d.category,
        ((SUM(fe.`quantity_sold(after_promo)`) * SUM(fe.base_price)) - (SUM(fe.`quantity_sold(before_promo)`) * SUM(fe.base_price))) / (SUM(fe.`quantity_sold(before_promo)`) * SUM(fe.base_price)) * 100 AS ir_percentage
    FROM
        fact_events fe
    JOIN dim_products d ON fe.product_code = d.product_code
    GROUP BY
        d.product_name,
        d.category
)
SELECT
    product_name,
    category,
    ir_percentage
FROM
    ProductIR
ORDER BY
    ir_percentage DESC
LIMIT
    5;

----------------------------------------------------
-- Promo IR Top 10 Stores

WITH StoreIR AS (
    SELECT
        s.store_id,
        SUM((fe.base_price * fe.`quantity_sold(after_promo)`) - (fe.base_price * fe.`quantity_sold(before_promo)`)) AS incremental_revenue
    FROM
        fact_events fe
    JOIN dim_stores s ON fe.store_id = s.store_id
    GROUP BY
        s.store_id
)
SELECT
    s.store_id,
    s.city,
    COALESCE(si.incremental_revenue, 0) AS incremental_revenue
FROM
    dim_stores s
LEFT JOIN
    StoreIR si ON s.store_id = si.store_id
ORDER BY
    incremental_revenue DESC
LIMIT
    10;

-- Promo ISU Bottom 10 Stores

WITH StoreISU AS (
    SELECT
        fe.store_id,
        SUM(fe.`quantity_sold(after_promo)`) - SUM(fe.`quantity_sold(before_promo)`) AS incremental_sold_units
    FROM
        fact_events fe
    GROUP BY
        fe.store_id
)
SELECT
    ds.store_id,
    ds.city,
    COALESCE(si.incremental_sold_units, 0) AS incremental_sold_units
FROM
    dim_stores ds
LEFT JOIN
    StoreISU si ON ds.store_id = si.store_id
ORDER BY
    incremental_sold_units ASC
LIMIT
    10;
    
-- Top 2 Promotion

WITH PromotionIR AS (
    SELECT
        f.promo_type,
        SUM((f.base_price * f.`quantity_sold(after_promo)`) - (f.base_price * f.`quantity_sold(before_promo)`)) AS incremental_revenue
    FROM
        fact_events f
    GROUP BY
        f.promo_type
)
SELECT
    promo_type,
    SUM(incremental_revenue) AS total_incremental_revenue
FROM
    PromotionIR
GROUP BY
    promo_type
ORDER BY
    total_incremental_revenue DESC
LIMIT
    2;

-- Bottom 2 Promotion

WITH PromotionISU AS (
    SELECT
        f.promo_type,
        SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) AS incremental_sold_units
    FROM
        fact_events f
    GROUP BY
        f.promo_type
)
SELECT
    promo_type,
    SUM(incremental_sold_units) AS total_incremental_sold_units
FROM
    PromotionISU
GROUP BY
    promo_type
ORDER BY
    total_incremental_sold_units ASC
LIMIT
    2;

-- return rate

SELECT 
    (SUM(CASE WHEN fe.quantity_returned > 0 THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS return_rate
FROM 
    fact_events fe;
    
    
-- orders after promo

SELECT SUM(fe.quantity_sold_before_promo) AS total_quantity_sold_before_promo
FROM fact_events fe
JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
WHERE fe.event_date < dc.start_date;










-- orders before promo

















