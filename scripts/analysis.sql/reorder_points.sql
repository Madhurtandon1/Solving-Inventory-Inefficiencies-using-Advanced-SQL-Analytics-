--ROP = Average Daily Demand × Lead Time

-- Step 1: Identify the latest 30-day window from available sales data
WITH DateRange AS (
    SELECT 
        DATEADD(DAY, -30, MAX(date)) AS start_date,
        MAX(date) AS end_date
    FROM Sales
),

-- Step 2: Calculate average daily sales per product-store-region
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
)

-- Step 3: Estimate reorder point (7-day lead time)
SELECT 
    ads.store_id,
    ads.region,
    ads.product_id,
    p.category,
    ROUND(ads.avg_daily_sales, 2) AS avg_daily_sales,
    ROUND(ads.avg_daily_sales * 7, 0) AS reorder_point,
	ROUND((ads.avg_daily_sales * 7) + 10, 0) AS reorder_point_with_safety

FROM AvgDailySales ads
JOIN Products p ON ads.product_id = p.product_id
ORDER BY reorder_point DESC;
