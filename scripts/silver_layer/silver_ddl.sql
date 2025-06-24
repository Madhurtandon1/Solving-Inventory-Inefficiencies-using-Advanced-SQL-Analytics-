CREATE OR ALTER PROCEDURE sp_RecreateInventorySchema
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '⚙ Starting schema recreation...';

    BEGIN TRY
        -- Drop dependent tables in correct order
        IF OBJECT_ID('Forecasts', 'U') IS NOT NULL DROP TABLE Forecasts;
        IF OBJECT_ID('Weather', 'U') IS NOT NULL DROP TABLE Weather;
        IF OBJECT_ID('Orders', 'U') IS NOT NULL DROP TABLE Orders;
        IF OBJECT_ID('Sales', 'U') IS NOT NULL DROP TABLE Sales;
        IF OBJECT_ID('Inventory', 'U') IS NOT NULL DROP TABLE Inventory;
        IF OBJECT_ID('Products', 'U') IS NOT NULL DROP TABLE Products;
        IF OBJECT_ID('Stores', 'U') IS NOT NULL DROP TABLE Stores;

        PRINT '🧱 Tables dropped. Creating new tables...';

        -- Stores (composite key)
        CREATE TABLE Stores (
            store_id VARCHAR(10),
            region VARCHAR(100),
            PRIMARY KEY (store_id, region)
        );
        PRINT ' Created Stores';

        -- Products
        CREATE TABLE Products (
            product_id VARCHAR(20) PRIMARY KEY,
            category VARCHAR(100),
            price DECIMAL(10, 2),
            seasonality VARCHAR(50)
        );
        PRINT ' Created Products';

        -- Inventory
        CREATE TABLE Inventory (
            inventory_id INT IDENTITY(1,1) PRIMARY KEY,
            store_id VARCHAR(10),
            region VARCHAR(100),
            product_id VARCHAR(20),
            date DATE,
            inventory_level INT,
            FOREIGN KEY (store_id, region) REFERENCES Stores(store_id, region),
            FOREIGN KEY (product_id) REFERENCES Products(product_id)
        );
        PRINT ' Created Inventory';

        -- Sales
        CREATE TABLE Sales (
            sale_id INT IDENTITY(1,1) PRIMARY KEY,
            store_id VARCHAR(10),
            region VARCHAR(100),
            product_id VARCHAR(20),
            date DATE,
            units_sold INT,
            discount DECIMAL(5, 2),
            holiday_promotion BIT,
            competitor_pricing DECIMAL(10, 2),
            FOREIGN KEY (store_id, region) REFERENCES Stores(store_id, region),
            FOREIGN KEY (product_id) REFERENCES Products(product_id)
        );
        PRINT ' Created Sales';

        -- Orders
        CREATE TABLE Orders (
            order_id INT IDENTITY(1,1) PRIMARY KEY,
            store_id VARCHAR(10),
            region VARCHAR(100),
            product_id VARCHAR(20),
            date DATE,
            units_ordered INT,
            FOREIGN KEY (store_id, region) REFERENCES Stores(store_id, region),
            FOREIGN KEY (product_id) REFERENCES Products(product_id)
        );
        PRINT ' Created Orders';

        -- Weather
        CREATE TABLE Weather (
            store_id VARCHAR(10),
            region VARCHAR(100),
            date DATE,
            condition VARCHAR(50),
            PRIMARY KEY (store_id, region, date),
            FOREIGN KEY (store_id, region) REFERENCES Stores(store_id, region)
        );
        PRINT ' Created Weather';

        -- Forecasts
        CREATE TABLE Forecasts (
            forecast_id INT IDENTITY(1,1) PRIMARY KEY,
            store_id VARCHAR(10),
            region VARCHAR(100),
            product_id VARCHAR(20),
            date DATE,
            demand_forecast FLOAT,
            FOREIGN KEY (store_id, region) REFERENCES Stores(store_id, region),
            FOREIGN KEY (product_id) REFERENCES Products(product_id)
        );
        PRINT ' Created Forecasts';

        PRINT ' Schema recreated successfully.';

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT ' Error while recreating schema:';
        PRINT @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;


