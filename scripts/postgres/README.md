# PostgreSQL Implementation

A PostgreSQL port of the inventory analytics pipeline, adding the pieces
the original SQL Server scripts didn't have: **views**, **triggers**, and
**stored procedures**, on top of the existing 3NF schema, CTEs, window
functions, and multi-table JOINs.

Run in order against a PostgreSQL database:

| # | File | Purpose |
|---|------|---------|
| 1 | `01_schema.sql` | Creates the `urban_retail` schema, the raw staging table, and the normalized `stores` / `products` / `inventory` / `sales` / `orders` / `weather` / `forecasts` tables (3NF), plus `inventory_audit_log`. |
| 2 | `02_load_bronze.sql` | Loads the raw CSV into the staging table via `COPY` / `\copy`. |
| 3 | `03_load_silver.sql` | Normalizes the staging data into the 3NF tables. |
| 4 | `04_views.sql` | Analytical **views** — `vw_stock_summary`, `vw_reorder_points`, `vw_low_inventory`, `vw_turnover_ratio`, `vw_kpi_summary` — for Power BI or any BI tool to connect to directly. |
| 5 | `05_triggers.sql` | **Triggers**: audit log on every insert/update to `inventory`, a guard against negative inventory levels, and an automatic inventory deduction when a sale is recorded. |
| 6 | `06_procedures.sql` | **Stored procedures**: `sp_recreate_inventory_schema()` to rebuild the schema, `sp_load_silver_from_bronze()` to run the full bronze → silver load, and `sp_refresh_low_stock_alert()` for on-demand low-stock lookups. |

## Quick start

```bash
psql -d urbanretail -f 01_schema.sql
psql -d urbanretail -f 02_load_bronze.sql   # edit the file path first
psql -d urbanretail -f 03_load_silver.sql
psql -d urbanretail -f 04_views.sql
psql -d urbanretail -f 05_triggers.sql
psql -d urbanretail -f 06_procedures.sql
```

Or, after the schema/data are loaded once, re-run the whole load with:

```sql
CALL sp_recreate_inventory_schema();
-- reload raw data, then:
CALL sp_load_silver_from_bronze();
```

## Power BI

Point Power BI's PostgreSQL connector at the `urban_retail` schema and
import the `vw_*` views directly (rather than the base tables) — DAX
measures for inventory turnover, stockout rate, and reorder thresholds
can be built straight on top of `vw_turnover_ratio`, `vw_kpi_summary`,
and `vw_low_inventory` without duplicating the underlying SQL logic.
