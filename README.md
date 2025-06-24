# Solving-Inventory-Inefficiencies-using-Advanced-SQL-Analytics-
Urban Retail Co. — Inventory Analytics Project

---

## Introduction

Urban Retail Co. is a fast-growing, mid-sized retail chain operating through both physical outlets and an online platform. With over 5,000 SKUs across cities, our offerings include groceries, personal care items, electronics, and home essentials. These are supported by a multi-regional logistics and warehousing system.

As our operations expand, we face challenges in maintaining optimal stock levels. While transactional and warehouse data is available, it remains largely underutilised — resulting in missed opportunities, overstocking, and increased operational costs.

---

## The Challenge

Urban Retail is currently facing the following problems:

- Frequent stockouts of fast-moving products, hurting customer satisfaction  
- Overstocking of slow-moving goods, tying up capital and increasing storage costs  
- Lack of real-time insights into SKU performance, reorder thresholds, and supplier behavior  
- Limited visibility across regions and product categories  

We believe that structured SQL-based analysis can provide the clarity and insights needed to tackle these inefficiencies.

---

## Project Objective

The objective of this project is to identify and resolve inventory inefficiencies at Urban Retail Co. by leveraging SQL-based data analysis. With a growing number of SKUs and geographic locations, the company struggles with:

- Stockouts of fast-selling products  
- Overstocking of slow-moving items  
- Inadequate visibility into inventory trends  
- Lack of data-driven decision-making  

The goal is to design a data-driven inventory monitoring system that provides actionable insights through SQL, enabling smarter stocking decisions, reducing losses, and improving customer satisfaction.

---

## How We Tackled It in the Code

We tackled the problem through a systematic pipeline of SQL scripts that simulate a full-stack analytics solution. Below is a breakdown:

---

### 1. Database & Schema Setup

- `database.sql`: Creates the `UrbanRetail` database and raw staging table `Raw_inventory_Datasets`  
- `silver_layer/proc_load_silver.sql`: Contains a stored procedure to normalize and populate structured tables:  
  `Products`, `Stores`, `Inventory`, `Sales`, `Orders`, `Weather`, `Forecasts`  

These tables follow relational principles to support performance and maintain data integrity.

---

### 2. Data Quality Checks

Before inserting into structured tables, we run validation queries to:

- Check for duplicate `Product ID`s and inconsistent `Store ID`–`Region` mappings  
- Ensure deduplication using `ROW_NUMBER()` in CTEs for latest records and unique inserts  

---

### 3. Analytics and Insights

Handled in `analysis` and `reorder_points.sql`:

#### Stock Level Calculations

- Total, regional, and store-level stock breakdowns  
- Use of `SUM()`, `GROUP BY`, and `JOIN`s to aggregate inventory  

#### Low Inventory Detection

- Calculates dynamic reorder points using 30-day sales history  
- Compares latest inventory against reorder thresholds  

#### Inventory Turnover Analysis

- Measures how quickly inventory is sold and replaced monthly  
- Uses monthly aggregation of sales and average inventory  

#### KPI Summary Reports

- Stockout rates (% days with zero inventory)  
- Inventory aging (how long items have been tracked)  
- Average stock levels  

All metrics are computed using layered CTEs, aggregates, and window functions.

---

## Output Impact

These queries serve as the backbone of a reporting system or dashboard that can:

- Flag understocked stores in real-time  
- Identify overstock trends  
- Recommend reorder quantities  
- Track inventory performance over time  

---

## Credits

Submitted to IIT Guwahati 
Tag: @caciitg
