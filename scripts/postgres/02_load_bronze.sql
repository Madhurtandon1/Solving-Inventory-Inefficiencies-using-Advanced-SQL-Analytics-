------------------------------------------------------------
-- Load raw CSV into the bronze staging table (PostgreSQL)
-- Note: path must be accessible to the Postgres server process.
-- If loading from a client machine instead, use psql's \copy.
------------------------------------------------------------

SET search_path TO urban_retail;

TRUNCATE TABLE raw_inventory_datasets;

COPY raw_inventory_datasets (
    date, store_id, product_id, category, region,
    inventory_level, units_sold, units_ordered, demand_forecast,
    price, discount, weather_condition, holiday_promotion,
    competitor_pricing, seasonality
)
FROM '/path/to/inventory_forecasting_clean.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    QUOTE '"',
    ENCODING 'UTF8'
);

-- Client-side alternative (run from psql, no server filesystem access needed):
-- \copy raw_inventory_datasets FROM 'inventory_forecasting_clean.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
