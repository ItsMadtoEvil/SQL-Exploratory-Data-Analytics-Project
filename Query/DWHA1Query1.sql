USE master;
GO

-- Drop and recreate database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics1')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics1;
END;
GO

CREATE DATABASE DataWarehouseAnalytics1;
GO

USE DataWarehouseAnalytics1;
GO

-- Create schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC ('CREATE SCHEMA gold');
GO

--------------------------------------------------
-- GOLD TABLES
--------------------------------------------------

CREATE TABLE gold.dim_customers (
    Customer_Key INT,
    Customer_Id INT,
    Customer_Number NVARCHAR(50),
    First_Name NVARCHAR(50),
    Last_Name NVARCHAR(50),
    Country NVARCHAR(50),
    Marital_Status NVARCHAR(50),
    Gender NVARCHAR(50),
    Birthdate DATE NULL,
    Create_Date DATE NULL
);
GO

CREATE TABLE gold.dim_products (
    Product_Key INT,
    Product_Id INT,
    Product_Number NVARCHAR(50),
    Product_Name NVARCHAR(50),
    Category_Id NVARCHAR(50),
    Category NVARCHAR(50),
    Subcategory NVARCHAR(50),
    Maintenance NVARCHAR(50),
    Cost INT,
    Product_Line NVARCHAR(50),
    Start_Date DATE NULL
);
GO

CREATE TABLE gold.fact_sales (
    Order_Number NVARCHAR(50),
    Product_Key INT,
    Customer_Key INT,
    Order_Date DATE NULL,
    Shipping_Date DATE NULL,
    Due_Date DATE NULL,
    Sales_Amount INT,
    Quantity TINYINT,
    Price INT
);
GO

--------------------------------------------------
-- STAGING TABLES (ALL DATES AS VARCHAR)
--------------------------------------------------

CREATE TABLE stg_dim_customers (
    Customer_Key INT,
    Customer_Id INT,
    Customer_Number NVARCHAR(50),
    First_Name NVARCHAR(50),
    Last_Name NVARCHAR(50),
    Country NVARCHAR(50),
    Marital_Status NVARCHAR(50),
    Gender NVARCHAR(50),
    Birthdate NVARCHAR(50),
    Create_Date NVARCHAR(50)
);
GO

CREATE TABLE stg_dim_products (
    Product_Key INT,
    Product_Id INT,
    Product_Number NVARCHAR(50),
    Product_Name NVARCHAR(50),
    Category_Id NVARCHAR(50),
    Category NVARCHAR(50),
    Subcategory NVARCHAR(50),
    Maintenance NVARCHAR(50),
    Cost INT,
    Product_Line NVARCHAR(50),
    Start_Date NVARCHAR(50)
);
GO

CREATE TABLE stg_fact_sales (
    Order_Number NVARCHAR(50),
    Product_Key INT,
    Customer_Key INT,
    Order_Date NVARCHAR(50),
    Shipping_Date NVARCHAR(50),
    Due_Date NVARCHAR(50),
    Sales_Amount INT,
    Quantity TINYINT,
    Price INT
);
GO

--------------------------------------------------
-- LOAD STAGING TABLES
--------------------------------------------------

BULK INSERT stg_dim_customers
FROM 'F:\Data Science Projects\Data Warehouse Analytics 1\Dataset\gold.dim_customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO

BULK INSERT stg_dim_products
FROM 'F:\Data Science Projects\Data Warehouse Analytics 1\Dataset\gold.dim_products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO

BULK INSERT stg_fact_sales
FROM 'F:\Data Science Projects\Data Warehouse Analytics 1\Dataset\gold.fact_sales.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO

--------------------------------------------------
-- INSERT INTO GOLD (SAFE DATE CONVERSION)
--------------------------------------------------

TRUNCATE TABLE gold.dim_customers;

INSERT INTO gold.dim_customers
SELECT
    Customer_Key,
    Customer_Id,
    Customer_Number,
    First_Name,
    Last_Name,
    Country,
    Marital_Status,
    Gender,
    TRY_CONVERT(DATE, NULLIF(Birthdate, '')),
    TRY_CONVERT(DATE, NULLIF(Create_Date, ''))
FROM stg_dim_customers;
GO

TRUNCATE TABLE gold.dim_products;

INSERT INTO gold.dim_products
SELECT
    Product_Key,
    Product_Id,
    Product_Number,
    Product_Name,
    Category_Id,
    Category,
    Subcategory,
    Maintenance,
    Cost,
    Product_Line,
    TRY_CONVERT(DATE, NULLIF(Start_Date, ''))
FROM stg_dim_products;
GO

TRUNCATE TABLE gold.fact_sales;

INSERT INTO gold.fact_sales
SELECT
    Order_Number,
    Product_Key,
    Customer_Key,
    TRY_CONVERT(DATE, NULLIF(Order_Date, '')),
    TRY_CONVERT(DATE, NULLIF(Shipping_Date, '')),
    TRY_CONVERT(DATE, NULLIF(Due_Date, '')),
    Sales_Amount,
    Quantity,
    Price
FROM stg_fact_sales;
GO
