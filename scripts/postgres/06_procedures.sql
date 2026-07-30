------------------------------------------------------------
-- Stored Procedures (PostgreSQL / PL/pgSQL)
------------------------------------------------------------

SET search_path TO urban_retail;

------------------------------------------------------------
-- sp_recreate_inventory_schema: drops and rebuilds the 3NF
-- tables (equivalent of the SQL Server sp_RecreateInventorySchema)
------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_recreate_inventory_schema()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Recreating inventory schema...';

    -- CASCADE also drops the vw_* analytical views and the
    -- sp_refresh_low_stock_alert() function, since they depend on
    -- these tables. Re-run 04_views.sql (and 05_triggers.sql, whose
    -- triggers are dropped along with their tables) afterwards.
    DROP TABLE IF EXISTS forecasts CASCADE;
    DROP TABLE IF EXISTS weather CASCADE;
    DROP TABLE IF EXISTS orders CASCADE;
    DROP TABLE IF EXISTS sales CASCADE;
    DROP TABLE IF EXISTS inventory CASCADE;
    DROP TABLE IF EXISTS products CASCADE;
    DROP TABLE IF EXISTS stores CASCADE;
    DROP TABLE IF EXISTS inventory_audit_log CASCADE;

    CREATE TABLE stores (
        store_id VARCHAR(10),
        region VARCHAR(100),
        PRIMARY KEY (store_id, region)
    );

    CREATE TABLE products (
        product_id VARCHAR(20) PRIMARY KEY,
        category VARCHAR(100),
        price DECIMAL(10, 2),
        seasonality VARCHAR(50)
    );

    CREATE TABLE inventory (
        inventory_id SERIAL PRIMARY KEY,
        store_id VARCHAR(10),
        region VARCHAR(100),
        product_id VARCHAR(20),
        date DATE,
        inventory_level INT NOT NULL CHECK (inventory_level >= 0),
        updated_at TIMESTAMP NOT NULL DEFAULT now(),
        FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region),
        FOREIGN KEY (product_id) REFERENCES products(product_id)
    );

    CREATE TABLE sales (
        sale_id SERIAL PRIMARY KEY,
        store_id VARCHAR(10),
        region VARCHAR(100),
        product_id VARCHAR(20),
        date DATE,
        units_sold INT,
        discount DECIMAL(5, 2),
        holiday_promotion BOOLEAN,
        competitor_pricing DECIMAL(10, 2),
        FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region),
        FOREIGN KEY (product_id) REFERENCES products(product_id)
    );

    CREATE TABLE orders (
        order_id SERIAL PRIMARY KEY,
        store_id VARCHAR(10),
        region VARCHAR(100),
        product_id VARCHAR(20),
        date DATE,
        units_ordered INT,
        FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region),
        FOREIGN KEY (product_id) REFERENCES products(product_id)
    );

    CREATE TABLE weather (
        store_id VARCHAR(10),
        region VARCHAR(100),
        date DATE,
        condition VARCHAR(50),
        PRIMARY KEY (store_id, region, date),
        FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region)
    );

    CREATE TABLE forecasts (
        forecast_id SERIAL PRIMARY KEY,
        store_id VARCHAR(10),
        region VARCHAR(100),
        product_id VARCHAR(20),
        date DATE,
        demand_forecast FLOAT,
        FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region),
        FOREIGN KEY (product_id) REFERENCES products(product_id)
    );

    CREATE TABLE inventory_audit_log (
        audit_id SERIAL PRIMARY KEY,
        inventory_id INT,
        store_id VARCHAR(10),
        region VARCHAR(100),
        product_id VARCHAR(20),
        old_level INT,
        new_level INT,
        change_type VARCHAR(10),
        changed_at TIMESTAMP NOT NULL DEFAULT now()
    );

    RAISE NOTICE 'Schema recreated successfully.';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error while recreating schema: %', SQLERRM;
        RAISE;
END;
$$;

------------------------------------------------------------
-- sp_load_silver_from_bronze: normalizes raw_inventory_datasets
-- into the 3NF tables (Products, Stores, Inventory, Sales,
-- Orders, Weather, Forecasts). Wraps 03_load_silver.sql so the
-- full bronze->silver load can be run with a single CALL.
------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_load_silver_from_bronze()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO products (product_id, category, price, seasonality)
    SELECT DISTINCT ON (TRIM(product_id))
        TRIM(product_id), category, price, seasonality
    FROM raw_inventory_datasets
    ORDER BY TRIM(product_id), date
    ON CONFLICT (product_id) DO NOTHING;

    INSERT INTO stores (store_id, region)
    SELECT DISTINCT TRIM(store_id), region
    FROM raw_inventory_datasets
    ON CONFLICT (store_id, region) DO NOTHING;

    INSERT INTO inventory (store_id, region, product_id, date, inventory_level)
    SELECT store_id, region, product_id, date, inventory_level
    FROM raw_inventory_datasets;

    INSERT INTO sales (store_id, region, product_id, date, units_sold, discount, holiday_promotion, competitor_pricing)
    SELECT store_id, region, product_id, date, units_sold, discount, COALESCE(holiday_promotion, false), competitor_pricing
    FROM raw_inventory_datasets;

    INSERT INTO orders (store_id, region, product_id, date, units_ordered)
    SELECT store_id, region, product_id, date, units_ordered
    FROM raw_inventory_datasets;

    INSERT INTO weather (store_id, region, date, condition)
    SELECT DISTINCT ON (TRIM(store_id), region, date)
        TRIM(store_id), region, date, weather_condition
    FROM raw_inventory_datasets
    ORDER BY TRIM(store_id), region, date
    ON CONFLICT (store_id, region, date) DO NOTHING;

    INSERT INTO forecasts (store_id, region, product_id, date, demand_forecast)
    SELECT store_id, region, product_id, date, demand_forecast
    FROM raw_inventory_datasets;

    RAISE NOTICE 'Silver layer loaded from bronze successfully.';
END;
$$;

------------------------------------------------------------
-- sp_refresh_low_stock_alert: returns the current low-inventory
-- list (wraps vw_low_inventory) filtered to a single region, for
-- Power BI's DAX measures / scheduled refresh to call directly.
------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_refresh_low_stock_alert(p_region VARCHAR DEFAULT NULL)
RETURNS SETOF vw_low_inventory
LANGUAGE sql
AS $$
    SELECT * FROM vw_low_inventory
    WHERE p_region IS NULL OR region = p_region
    ORDER BY inventory_level ASC;
$$;

-- Usage:
--   CALL sp_recreate_inventory_schema();   -- drops tables CASCADE, so also
--                                           -- drops vw_* views/functions/triggers
--   \i 04_views.sql                        -- recreate the analytical views
--   \i 05_triggers.sql                     -- recreate the triggers
--   CALL sp_load_silver_from_bronze();
--   SELECT * FROM sp_refresh_low_stock_alert('West');
