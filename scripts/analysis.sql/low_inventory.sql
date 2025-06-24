-- Reorder Point = 7 days of average recent daily sales

-- STEP 1: Get Latest Inventory per product-store
WITH 
-- 1) Grab the latest inventory record per store/region/product
LatestInventory AS (
    SELECT 
        store_id,
        region,
        product_id,
        inventory_level,
        date,
        ROW_NUMBER() 
            OVER (
                PARTITION BY store_id, region, product_id 
                ORDER BY date DESC
            ) AS rn
    FROM Inventory
),

-- 2) Compute the 30-day window based on your Sales data
DateRange AS (
    SELECT 
        DATEADD(DAY, -30, MAX(date)) AS start_date,
        MAX(date)                        AS end_date
    FROM Sales
),

-- 3) Average daily sales over that 30-day window
AvgDailySales AS (
    SELECT 
        s.store_id,
        s.region,
        s.product_id,
        AVG(CAST(s.units_sold AS FLOAT)) AS avg_daily_sales
    FROM Sales s
    JOIN DateRange d 
      ON s.date BETWEEN d.start_date AND d.end_date
    GROUP BY 
        s.store_id,
        s.region,
        s.product_id
),

-- 4) Calculate a 7-day lead-time reorder point
ReorderPoints AS (
    SELECT 
        store_id,
        region,
        product_id,
        ROUND(avg_daily_sales * 7, 0) AS reorder_point
    FROM AvgDailySales
)

-- 5) Now join latest inventory to reorder points and flag low stock
SELECT 
    li.store_id,
    li.region,
    li.product_id,
    p.category,
    li.inventory_level,
    rp.reorder_point,
    li.date AS inventory_date
FROM LatestInventory li
INNER JOIN ReorderPoints rp 
    ON li.store_id   = rp.store_id
   AND li.region     = rp.region
   AND li.product_id = rp.product_id
INNER JOIN Products p 
    ON li.product_id = p.product_id
WHERE 
    li.rn = 1                       -- only the most recent inventory record
    AND li.inventory_level < rp.reorder_point
ORDER BY 
    li.inventory_level ASC;
