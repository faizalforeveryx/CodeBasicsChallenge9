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