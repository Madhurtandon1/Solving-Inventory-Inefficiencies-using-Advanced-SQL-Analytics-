------------------------------------------------------------
--  Products Table Insert
-- Only insert one row per unique Product ID
------------------------------------------------------------
WITH RankedProducts AS (
    SELECT
        TRIM([Product ID]) AS product_id,
        [Category],
        [Price],
        [Seasonality],
        ROW_NUMBER() OVER (PARTITION BY TRIM([Product ID]) ORDER BY [Date]) AS rn
    FROM Raw_inventory_Datasets
)
INSERT INTO Products (product_id, category, price, seasonality)
SELECT 
    product_id,
    [Category],
    [Price],
    [Seasonality]
FROM RankedProducts
WHERE rn = 1;


------------------------------------------------------------
--  Stores Table Insert
-- Insert all unique (Store ID, Region) combinations
------------------------------------------------------------
INSERT INTO Stores (store_id, region)
SELECT DISTINCT
    TRIM([Store ID]), 
    [Region]
FROM Raw_inventory_Datasets;


------------------------------------------------------------
--  Inventory Table Insert
-- Includes store_id and region to support composite key FK
------------------------------------------------------------
INSERT INTO Inventory (store_id, region, product_id, date, inventory_level)
SELECT 
    [Store ID], 
    [Region],
    [Product ID], 
    [Date], 
    [Inventory Level]
FROM Raw_inventory_Datasets;


------------------------------------------------------------
--  Sales Table Insert
-- Holiday/Promotion converted to BIT (0 or 1)
------------------------------------------------------------
INSERT INTO Sales (
    store_id, region, product_id, date, 
    units_sold, discount, holiday_promotion, competitor_pricing
)
SELECT 
    [Store ID], 
    [Region],
    [Product ID], 
    [Date], 
    [Units Sold], 
    [Discount], 
    CASE 
        WHEN [Holiday/Promotion] IN ('1') THEN 1 ELSE 0
    END,
    [Competitor Pricing]
FROM Raw_inventory_Datasets;


------------------------------------------------------------
--  Orders Table Insert
------------------------------------------------------------
INSERT INTO Orders (store_id, region, product_id, date, units_ordered)
SELECT 
    [Store ID], 
    [Region],
    [Product ID], 
    [Date], 
    [Units Ordered]
FROM Raw_inventory_Datasets;


------------------------------------------------------------
--  Weather Table Insert
-- Handles duplicate entries per store/region/date with ROW_NUMBER
------------------------------------------------------------
WITH RankedWeather AS (
    SELECT 
        TRIM([Store ID]) AS store_id,
        [Region] AS region,
        [Date] AS weather_date,
        [Weather Condition] AS condition,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM([Store ID]), [Region], [Date]
            ORDER BY [Weather Condition]  -- Arbitrary tiebreaker
        ) AS rn
    FROM Raw_inventory_Datasets
)
INSERT INTO Weather (store_id, region, date, condition)
SELECT store_id, region, weather_date, condition
FROM RankedWeather
WHERE rn = 1;


------------------------------------------------------------
--  Forecasts Table Insert
------------------------------------------------------------
INSERT INTO Forecasts (store_id, region, product_id, date, demand_forecast)
SELECT 
    [Store ID], 
    [Region],
    [Product ID], 
    [Date], 
    [Demand Forecast]
FROM Raw_inventory_Datasets;
