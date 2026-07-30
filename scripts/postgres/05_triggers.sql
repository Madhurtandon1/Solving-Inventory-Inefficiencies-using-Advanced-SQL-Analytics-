------------------------------------------------------------
-- Triggers (PostgreSQL)
-- Keeps inventory_audit_log in sync and enforces data integrity
-- directly at the database layer.
------------------------------------------------------------

SET search_path TO urban_retail;

------------------------------------------------------------
-- trg_inventory_audit: logs every insert/update to inventory
------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_inventory_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO inventory_audit_log
            (inventory_id, store_id, region, product_id, old_level, new_level, change_type)
        VALUES
            (NEW.inventory_id, NEW.store_id, NEW.region, NEW.product_id, NULL, NEW.inventory_level, 'INSERT');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO inventory_audit_log
            (inventory_id, store_id, region, product_id, old_level, new_level, change_type)
        VALUES
            (NEW.inventory_id, NEW.store_id, NEW.region, NEW.product_id, OLD.inventory_level, NEW.inventory_level, 'UPDATE');
        NEW.updated_at := now();
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_inventory_audit ON inventory;
CREATE TRIGGER trg_inventory_audit
    BEFORE INSERT OR UPDATE ON inventory
    FOR EACH ROW
    EXECUTE FUNCTION fn_inventory_audit();

------------------------------------------------------------
-- trg_prevent_negative_inventory: blocks writes that would drop
-- inventory below zero (defense in depth alongside the CHECK
-- constraint, and gives a descriptive error message)
------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_prevent_negative_inventory()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.inventory_level < 0 THEN
        RAISE EXCEPTION 'Inventory level cannot be negative (store %, region %, product %)',
            NEW.store_id, NEW.region, NEW.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_negative_inventory ON inventory;
CREATE TRIGGER trg_prevent_negative_inventory
    BEFORE INSERT OR UPDATE ON inventory
    FOR EACH ROW
    EXECUTE FUNCTION fn_prevent_negative_inventory();

------------------------------------------------------------
-- trg_sales_deducts_inventory: when a sale is recorded, decrement
-- the matching inventory row for that store/region/product/date
-- so Inventory always reflects units sold that day.
------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_sales_deducts_inventory()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory
    SET inventory_level = GREATEST(inventory_level - NEW.units_sold, 0)
    WHERE store_id = NEW.store_id
      AND region = NEW.region
      AND product_id = NEW.product_id
      AND date = NEW.date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sales_deducts_inventory ON sales;
CREATE TRIGGER trg_sales_deducts_inventory
    AFTER INSERT ON sales
    FOR EACH ROW
    EXECUTE FUNCTION fn_sales_deducts_inventory();
