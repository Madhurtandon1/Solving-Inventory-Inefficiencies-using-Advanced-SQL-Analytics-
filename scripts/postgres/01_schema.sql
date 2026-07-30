------------------------------------------------------------
-- PostgreSQL Schema (3NF Normalized)
-- UrbanRetail Inventory Analytics
------------------------------------------------------------
-- Run this first. Creates the raw staging table plus the
-- normalized Stores / Products / Inventory / Sales / Orders /
-- Weather / Forecasts tables used across 20+ retail outlets.
------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS urban_retail;
SET search_path TO urban_retail;

------------------------------------------------------------
-- Raw staging table (mirrors the source CSV)
------------------------------------------------------------
DROP TABLE IF EXISTS raw_inventory_datasets;

CREATE TABLE raw_inventory_datasets (
    date                DATE,
    store_id            VARCHAR(10),
    product_id          VARCHAR(20),
    category            VARCHAR(100),
    region              VARCHAR(100),
    inventory_level     INT,
    units_sold          INT,
    units_ordered       INT,
    demand_forecast     FLOAT,
    price               DECIMAL(10, 2),
    discount            DECIMAL(5, 2),
    weather_condition   VARCHAR(50),
    holiday_promotion   BOOLEAN,
    competitor_pricing  DECIMAL(10, 2),
    seasonality         VARCHAR(50)
);

------------------------------------------------------------
-- Normalized (3NF) tables
------------------------------------------------------------
DROP TABLE IF EXISTS forecasts;
DROP TABLE IF EXISTS weather;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS inventory_audit_log;

-- Stores: one row per (store_id, region) -- supports 20+ retail outlets
CREATE TABLE stores (
    store_id    VARCHAR(10),
    region      VARCHAR(100),
    PRIMARY KEY (store_id, region)
);

-- Products
CREATE TABLE products (
    product_id  VARCHAR(20) PRIMARY KEY,
    category    VARCHAR(100),
    price       DECIMAL(10, 2),
    seasonality VARCHAR(50)
);

-- Inventory
CREATE TABLE inventory (
    inventory_id     SERIAL PRIMARY KEY,
    store_id         VARCHAR(10),
    region           VARCHAR(100),
    product_id       VARCHAR(20),
    date             DATE,
    inventory_level  INT NOT NULL CHECK (inventory_level >= 0),
    updated_at       TIMESTAMP NOT NULL DEFAULT now(),
    FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Sales
CREATE TABLE sales (
    sale_id             SERIAL PRIMARY KEY,
    store_id            VARCHAR(10),
    region              VARCHAR(100),
    product_id          VARCHAR(20),
    date                DATE,
    units_sold          INT,
    discount            DECIMAL(5, 2),
    holiday_promotion   BOOLEAN,
    competitor_pricing  DECIMAL(10, 2),
    FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Orders
CREATE TABLE orders (
    order_id        SERIAL PRIMARY KEY,
    store_id        VARCHAR(10),
    region          VARCHAR(100),
    product_id      VARCHAR(20),
    date            DATE,
    units_ordered   INT,
    FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Weather
CREATE TABLE weather (
    store_id    VARCHAR(10),
    region      VARCHAR(100),
    date        DATE,
    condition   VARCHAR(50),
    PRIMARY KEY (store_id, region, date),
    FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region)
);

-- Forecasts
CREATE TABLE forecasts (
    forecast_id      SERIAL PRIMARY KEY,
    store_id         VARCHAR(10),
    region           VARCHAR(100),
    product_id       VARCHAR(20),
    date             DATE,
    demand_forecast  FLOAT,
    FOREIGN KEY (store_id, region) REFERENCES stores(store_id, region),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Audit trail written to by the inventory triggers (see 05_triggers.sql)
CREATE TABLE inventory_audit_log (
    audit_id         SERIAL PRIMARY KEY,
    inventory_id     INT,
    store_id         VARCHAR(10),
    region           VARCHAR(100),
    product_id       VARCHAR(20),
    old_level        INT,
    new_level        INT,
    change_type      VARCHAR(10),
    changed_at       TIMESTAMP NOT NULL DEFAULT now()
);

------------------------------------------------------------
-- Indexes to support the analytical views/reports
------------------------------------------------------------
CREATE INDEX idx_inventory_lookup ON inventory (product_id, store_id, region, date);
CREATE INDEX idx_sales_lookup     ON sales (product_id, store_id, region, date);
