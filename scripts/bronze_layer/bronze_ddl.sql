------------------------------------------------------------
--  STEP 1: Create Database
------------------------------------------------------------
IF DB_ID('UrbanRetail') IS NULL
BEGIN
    CREATE DATABASE UrbanRetail;
    PRINT ' Database "UrbanRetail" created.';
END
ELSE
BEGIN
    PRINT 'ℹ Database "UrbanRetail" already exists.';
END
GO

USE UrbanRetail;
GO

------------------------------------------------------------
--  STEP 2: Create Raw Data Table (Same Structure as CSV)
------------------------------------------------------------
IF OBJECT_ID('Raw_inventory_Datasets', 'U') IS NOT NULL
    DROP TABLE Raw_inventory_Datasets;
GO

CREATE TABLE Raw_inventory_Datasets (
    [Date] DATE,
    [Store ID] VARCHAR(10),
    [Product ID] VARCHAR(20),
    [Category] VARCHAR(100),
    [Region] VARCHAR(100),
    [Inventory Level] INT,
    [Units Sold] INT,
    [Units Ordered] INT,
    [Demand Forecast] FLOAT,
    [Price] DECIMAL(10,2),
    [Discount] DECIMAL(5,2),
    [Weather Condition] VARCHAR(50),
    [Holiday/Promotion] BIT,
    [Competitor Pricing] DECIMAL(10,2),
    [Seasonality] VARCHAR(50)
);
PRINT ' Table "Raw_inventory_Datasets" created.';
GO





