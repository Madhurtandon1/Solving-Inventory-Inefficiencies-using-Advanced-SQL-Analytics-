-- Step 1: Calculate total units sold per product-store-region per month
WITH MonthlySales AS (
    SELECT 
        product_id,
        store_id,
        region,
        FORMAT(date, 'yyyy-MM') AS sales_month,
        SUM(units_sold) AS total_units_sold
    FROM Sales
    GROUP BY product_id, store_id, region, FORMAT(date, 'yyyy-MM')
),

-- Step 2: Calculate average inventory level per product-store-region per month
MonthlyInventory AS (
    SELECT 
        product_id,
        store_id,
        region,
        FORMAT(date, 'yyyy-MM') AS inventory_month,
        AVG(CAST(inventory_level AS FLOAT)) AS avg_inventory
    FROM Inventory
    GROUP BY product_id, store_id, region, FORMAT(date, 'yyyy-MM')
),

-- Step 3: Join sales and inventory by product-store-region-month
TurnoverPerMonth AS (
    SELECT 
        s.product_id,
        p.category,
        s.store_id,
        s.region,
        s.sales_month,
        s.total_units_sold,
        i.avg_inventory,
        
        -- Turnover calculation for that month
        CASE 
            WHEN i.avg_inventory > 0 
                THEN ROUND(s.total_units_sold / i.avg_inventory, 2)
            ELSE NULL
        END AS inventory_turnover_ratio
    FROM MonthlySales s
    JOIN MonthlyInventory i 
        ON s.product_id = i.product_id
        AND s.store_id = i.store_id
        AND s.region = i.region
        AND s.sales_month = i.inventory_month
    JOIN Products p 
        ON s.product_id = p.product_id
)

-- Final SELECT: include rating and sort by month + turnover
SELECT 
    product_id,
    category,
    store_id,
    region,
    sales_month,
    total_units_sold,
    avg_inventory,
    inventory_turnover_ratio,

    -- Rating based on monthly turnover ranges (adjust if needed)
     CASE 
        WHEN inventory_turnover_ratio >= 8 THEN 'High'
        WHEN inventory_turnover_ratio >= 4 THEN 'Moderate'
        WHEN inventory_turnover_ratio IS NOT NULL THEN 'Low'
        ELSE 'N/A'
    END AS turnover_rating

FROM TurnoverPerMonth
ORDER BY sales_month, inventory_turnover_ratio DESC;
