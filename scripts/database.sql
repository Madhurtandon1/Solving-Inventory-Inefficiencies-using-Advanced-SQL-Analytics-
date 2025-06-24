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
    PRINT ' Database "UrbanRetail" already exists.';
END
GO

USE UrbanRetail;
GO

------------------------------------------------------------
-- STEP 2: Create Raw Data Table (Same Structure as CSV)
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

------------------------------------------------------------
--  STEP 3: Bulk Insert Data from CSV File
-- Note: Ensure the file path is accessible to SQL Server
-- File must be accessible from SQL Server's host system
------------------------------------------------------------
-- Example: Change the path below to match your actual CSV file location

BULK INSERT Raw_inventory_Datasets
FROM 'C:\Path\To\Your\File\inventory_forecasting_clean.csv'
WITH (
    FIRSTROW = 2,                          -- Skip header
    FIELDTERMINATOR = ',',                -- CSV separator
    ROWTERMINATOR = '\n',                 -- Line break
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001'                    -- For UTF-8
);

PRINT ' Data loaded successfully into "Raw_inventory_Datasets".';
