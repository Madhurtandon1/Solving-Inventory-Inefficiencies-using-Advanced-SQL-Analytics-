-----------------------------------------------------------
--  STEP 1: Bulk Insert Data from CSV File
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
