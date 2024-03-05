-- Q1: Identify High-Value Products in BOGOF Promotion
SELECT p.product_code, p.product_name, p.category, f.base_price, f.promo_type
FROM dim_products p
JOIN fact_events f ON p.product_code = f.product_code
JOIN dim_campaigns c ON f.campaign_id = c.campaign_id
WHERE f.base_price > 500
AND f.promo_type = 'BOGOF';

-- Q2: City-wise Store Count Overview
SELECT city, COUNT(store_id) AS store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

-- Q3: Campaign Revenue Impact Report
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

-- Q4: Diwali Campaign ISU% Analysis
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
    
-- Q5: Top 5 Products by IR% Across Campaigns
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








