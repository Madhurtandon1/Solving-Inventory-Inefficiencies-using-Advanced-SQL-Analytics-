------------------------------------------------------------
-- Bronze -> Silver load (PostgreSQL)
-- Normalizes Raw_inventory_datasets into the 3NF tables.
------------------------------------------------------------

SET search_path TO urban_retail;

------------------------------------------------------------
-- Products: one row per unique product_id
------------------------------------------------------------
INSERT INTO products (product_id, category, price, seasonality)
SELECT DISTINCT ON (TRIM(product_id))
    TRIM(product_id) AS product_id,
    category,
    price,
    seasonality
FROM raw_inventory_datasets
ORDER BY TRIM(product_id), date
ON CONFLICT (product_id) DO NOTHING;

------------------------------------------------------------
-- Stores: one row per unique (store_id, region)
------------------------------------------------------------
INSERT INTO stores (store_id, region)
SELECT DISTINCT TRIM(store_id), region
FROM raw_inventory_datasets
ON CONFLICT (store_id, region) DO NOTHING;

------------------------------------------------------------
-- Inventory
------------------------------------------------------------
INSERT INTO inventory (store_id, region, product_id, date, inventory_level)
SELECT store_id, region, product_id, date, inventory_level
FROM raw_inventory_datasets;

------------------------------------------------------------
-- Sales
------------------------------------------------------------
INSERT INTO sales (
    store_id, region, product_id, date,
    units_sold, discount, holiday_promotion, competitor_pricing
)
SELECT
    store_id, region, product_id, date,
    units_sold, discount,
    COALESCE(holiday_promotion, false),
    competitor_pricing
FROM raw_inventory_datasets;

------------------------------------------------------------
-- Orders
------------------------------------------------------------
INSERT INTO orders (store_id, region, product_id, date, units_ordered)
SELECT store_id, region, product_id, date, units_ordered
FROM raw_inventory_datasets;

------------------------------------------------------------
-- Weather: dedupe per store/region/date
------------------------------------------------------------
INSERT INTO weather (store_id, region, date, condition)
SELECT DISTINCT ON (TRIM(store_id), region, date)
    TRIM(store_id), region, date, weather_condition
FROM raw_inventory_datasets
ORDER BY TRIM(store_id), region, date
ON CONFLICT (store_id, region, date) DO NOTHING;

------------------------------------------------------------
-- Forecasts
------------------------------------------------------------
INSERT INTO forecasts (store_id, region, product_id, date, demand_forecast)
SELECT store_id, region, product_id, date, demand_forecast
FROM raw_inventory_datasets;
