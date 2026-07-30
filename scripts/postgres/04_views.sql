------------------------------------------------------------
-- Analytical Views (PostgreSQL)
-- Wraps the CTE/window-function reports as queryable views so
-- Power BI (or any BI tool) can connect directly to a stable
-- interface instead of embedding raw SQL in the report layer.
------------------------------------------------------------

SET search_path TO urban_retail;

------------------------------------------------------------
-- vw_stock_summary: total stock by product, and by product+region
------------------------------------------------------------
CREATE OR REPLACE VIEW vw_stock_summary AS
SELECT
    i.product_id,
    p.category,
    i.region,
    i.store_id,
    SUM(i.inventory_level) AS total_stock
FROM inventory i
JOIN products p ON i.product_id = p.product_id
GROUP BY i.product_id, p.category, i.region, i.store_id;

------------------------------------------------------------
-- vw_reorder_points: 30-day average daily sales -> 7-day reorder point
------------------------------------------------------------
CREATE OR REPLACE VIEW vw_reorder_points AS
WITH date_range AS (
    SELECT MAX(date) - INTERVAL '30 days' AS start_date,
           MAX(date)                      AS end_date
    FROM sales
),
avg_daily_sales AS (
    SELECT
        s.store_id,
        s.region,
        s.product_id,
        AVG(s.units_sold::FLOAT) AS avg_daily_sales
    FROM sales s
    JOIN date_range d ON s.date BETWEEN d.start_date AND d.end_date
    GROUP BY s.store_id, s.region, s.product_id
)
SELECT
    ads.store_id,
    ads.region,
    ads.product_id,
    p.category,
    ROUND(ads.avg_daily_sales::NUMERIC, 2)                  AS avg_daily_sales,
    ROUND((ads.avg_daily_sales * 7)::NUMERIC, 0)             AS reorder_point,
    ROUND((ads.avg_daily_sales * 7 + 10)::NUMERIC, 0)        AS reorder_point_with_safety
FROM avg_daily_sales ads
JOIN products p ON ads.product_id = p.product_id;

------------------------------------------------------------
-- vw_low_inventory: latest inventory vs. reorder point, flags what needs restocking
------------------------------------------------------------
CREATE OR REPLACE VIEW vw_low_inventory AS
WITH latest_inventory AS (
    SELECT
        store_id, region, product_id, inventory_level, date,
        ROW_NUMBER() OVER (
            PARTITION BY store_id, region, product_id
            ORDER BY date DESC
        ) AS rn
    FROM inventory
)
SELECT
    li.store_id,
    li.region,
    li.product_id,
    p.category,
    li.inventory_level,
    rp.reorder_point,
    li.date AS inventory_date
FROM latest_inventory li
JOIN vw_reorder_points rp
    ON li.store_id = rp.store_id
   AND li.region = rp.region
   AND li.product_id = rp.product_id
JOIN products p ON li.product_id = p.product_id
WHERE li.rn = 1
  AND li.inventory_level < rp.reorder_point;

------------------------------------------------------------
-- vw_turnover_ratio: monthly inventory turnover per product/store/region
------------------------------------------------------------
CREATE OR REPLACE VIEW vw_turnover_ratio AS
WITH monthly_sales AS (
    SELECT
        product_id, store_id, region,
        TO_CHAR(date, 'YYYY-MM') AS sales_month,
        SUM(units_sold) AS total_units_sold
    FROM sales
    GROUP BY product_id, store_id, region, TO_CHAR(date, 'YYYY-MM')
),
monthly_inventory AS (
    SELECT
        product_id, store_id, region,
        TO_CHAR(date, 'YYYY-MM') AS inventory_month,
        AVG(inventory_level::FLOAT) AS avg_inventory
    FROM inventory
    GROUP BY product_id, store_id, region, TO_CHAR(date, 'YYYY-MM')
)
SELECT
    s.product_id,
    p.category,
    s.store_id,
    s.region,
    s.sales_month,
    s.total_units_sold,
    i.avg_inventory,
    CASE WHEN i.avg_inventory > 0
         THEN ROUND((s.total_units_sold / i.avg_inventory)::NUMERIC, 2)
         ELSE NULL
    END AS inventory_turnover_ratio,
    CASE
        WHEN i.avg_inventory > 0 AND s.total_units_sold / i.avg_inventory >= 8 THEN 'High'
        WHEN i.avg_inventory > 0 AND s.total_units_sold / i.avg_inventory >= 4 THEN 'Moderate'
        WHEN i.avg_inventory > 0 THEN 'Low'
        ELSE 'N/A'
    END AS turnover_rating
FROM monthly_sales s
JOIN monthly_inventory i
    ON s.product_id = i.product_id
   AND s.store_id = i.store_id
   AND s.region = i.region
   AND s.sales_month = i.inventory_month
JOIN products p ON s.product_id = p.product_id;

------------------------------------------------------------
-- vw_kpi_summary: stockout rate, avg inventory, inventory age
------------------------------------------------------------
CREATE OR REPLACE VIEW vw_kpi_summary AS
WITH inventory_status AS (
    SELECT
        product_id, store_id, region,
        COUNT(*) AS total_days,
        SUM(CASE WHEN inventory_level = 0 THEN 1 ELSE 0 END) AS stockout_days
    FROM inventory
    GROUP BY product_id, store_id, region
),
avg_inventory AS (
    SELECT
        product_id, store_id, region,
        AVG(inventory_level::FLOAT) AS avg_inventory
    FROM inventory
    GROUP BY product_id, store_id, region
),
inventory_age AS (
    SELECT
        product_id, store_id, region,
        (MAX(date) - MIN(date)) AS inventory_span_days,
        AVG(inventory_level::FLOAT) AS avg_inventory_age
    FROM inventory
    GROUP BY product_id, store_id, region
)
SELECT
    s.product_id,
    p.category,
    s.store_id,
    s.region,
    ROUND((100.0 * s.stockout_days / NULLIF(s.total_days, 0))::NUMERIC, 2) AS stockout_rate_percent,
    ROUND(a.avg_inventory::NUMERIC, 2) AS avg_inventory_level,
    ia.inventory_span_days AS inventory_days_tracked,
    ROUND(ia.avg_inventory_age::NUMERIC, 2) AS avg_inventory_age
FROM inventory_status s
JOIN avg_inventory a
    ON s.product_id = a.product_id AND s.store_id = a.store_id AND s.region = a.region
JOIN inventory_age ia
    ON s.product_id = ia.product_id AND s.store_id = ia.store_id AND s.region = ia.region
JOIN products p ON s.product_id = p.product_id;
