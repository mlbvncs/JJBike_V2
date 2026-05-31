-- Date helpers (reused across all loads)
DECLARE @dt_end   DATETIME = GETDATE();              -- Captures the exact moment of execution; used to "close" the old record by filling validity_end_date.
DECLARE @dt_start DATETIME = DATEADD(MILLISECOND, 3, @dt_end); -- 3 milliseconds after @dt_end; used as validity_start_date for the new record created after a change.

-- ── DIMENSION LOADS (SCD Type 2) ─────────────────────────────────────────────

-- LOAD CUSTOMER DATA (1st LOAD)
INSERT INTO Dimensional..dim_customer (id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date)
SELECT id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date
FROM (
    -- Find all records where IDs match in source and destination (and that are currently active)
    MERGE Dimensional..dim_customer AS T
    USING Relational..customers AS S
    ON (T.id_customer = S.id_customer AND T.validity_end_date IS NULL)
    -- If the customer's attributes changed, close the current history record
    WHEN MATCHED AND (S.customer_name <> T.customer_name OR S.customer_state <> T.customer_state OR S.customer_gender <> T.customer_gender OR S.customer_status <> T.customer_status)
        THEN UPDATE SET T.validity_end_date = @dt_end
    -- If the customer does not exist in the DW, insert with the current system date
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date)
             VALUES (S.id_customer, S.customer_name, S.customer_state, S.customer_gender, S.customer_status, @dt_start, NULL)
    -- OUTPUT captures whether a row was closed, so a new active history row can be created
    OUTPUT $ACTION AS action, S.id_customer, S.customer_name, S.customer_state, S.customer_gender, S.customer_status, @dt_start AS validity_start_date, NULL AS validity_end_date
) AS O WHERE O.action = 'UPDATE'; -- Filter to re-insert only the records that were changed (inserts are already handled by MERGE)

-- LOAD PRODUCT DATA (1st LOAD)
INSERT INTO Dimensional..dim_product (id_product, product_name, validity_start_date, validity_end_date)
SELECT id_product, product_name, validity_start_date, validity_end_date
FROM (
    -- Find all records where IDs match in source and destination (and that are currently active)
    MERGE Dimensional..dim_product AS T
    USING Relational..products AS S
    ON (T.id_product = S.id_product AND T.validity_end_date IS NULL)
    -- If the product name changed, close the current history record
    WHEN MATCHED AND (S.product_name <> T.product_name)
        THEN UPDATE SET T.validity_end_date = @dt_end
    -- If the product does not exist in the DW, insert with the current system date
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (id_product, product_name, validity_start_date, validity_end_date)
             VALUES (S.id_product, S.product_name, @dt_start, NULL)
    -- OUTPUT captures whether a row was closed, so a new active history row can be created
    OUTPUT $ACTION AS action, S.id_product, S.product_name, @dt_start AS validity_start_date, NULL AS validity_end_date
) AS O WHERE O.action = 'UPDATE'; -- Filter to re-insert only the records that were changed (inserts are already handled by MERGE)

-- LOAD SELLER DATA (1st LOAD)
INSERT INTO Dimensional..dim_seller (id_seller, seller_name, validity_start_date, validity_end_date)
SELECT id_seller, seller_name, validity_start_date, validity_end_date
FROM (
    -- Find all records where IDs match in source and destination (and that are currently active)
    MERGE Dimensional..dim_seller AS T
    USING Relational..sellers AS S
    ON (T.id_seller = S.id_seller AND T.validity_end_date IS NULL)
    -- If the seller name changed, close the current history record
    WHEN MATCHED AND (S.seller_name <> T.seller_name)
        THEN UPDATE SET T.validity_end_date = @dt_end
    -- If the seller does not exist in the DW, insert with the current system date
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (id_seller, seller_name, validity_start_date, validity_end_date)
             VALUES (S.id_seller, S.seller_name, @dt_start, NULL)
    -- OUTPUT captures whether a row was closed, so a new active history row can be created
    OUTPUT $ACTION AS action, S.id_seller, S.seller_name, @dt_start AS validity_start_date, NULL AS validity_end_date
) AS O WHERE O.action = 'UPDATE'; -- Filter to re-insert only the records that were changed (inserts are already handled by MERGE)

-- LOAD ONLY THE MONTH OF JANUARY INTO fact_sales
INSERT INTO Dimensional..fact_sales (seller_key, customer_key, product_key, time_key, quantity, unit_price, total_price, discount)
SELECT
    vdd.seller_key,
    c.customer_key,
    p.product_key,
    t.time_key,
    iv.quantity,
    iv.unit_price,
    iv.total_price,
    iv.discount
FROM Relational..sales v
INNER JOIN Dimensional..dim_seller vdd   ON v.id_seller   = vdd.id_seller   AND vdd.validity_end_date IS NULL -- IS NULL represents the current seller record at the time of the fact load
INNER JOIN Relational..sale_items iv     ON v.id_sale     = iv.id_sale
INNER JOIN Dimensional..dim_customer c   ON v.id_customer = c.id_customer   AND c.validity_end_date   IS NULL -- IS NULL represents the current customer record at the time of the fact load
INNER JOIN Dimensional..dim_product p    ON iv.id_product = p.id_product    AND p.validity_end_date   IS NULL -- IS NULL represents the current product record at the time of the fact load
INNER JOIN Dimensional..dim_time t       ON v.sale_date   = t.time_date
WHERE MONTH(v.sale_date) = 1; -- JANUARY

-- A plan change is made for customers with IDs 1 to 5
UPDATE Relational..customers
SET customer_status = 'Gold'
WHERE id_customer BETWEEN 1 AND 5;

-- LOAD CUSTOMER DATA. WILL ONLY PROCESS HISTORY ON MODIFIED RECORDS (CUSTOMERS WITH IDs 1 TO 5)
INSERT INTO Dimensional..dim_customer (id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date)
SELECT id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date
FROM (
    MERGE Dimensional..dim_customer AS T
    USING Relational..customers AS S
    ON (T.id_customer = S.id_customer AND T.validity_end_date IS NULL)
    WHEN MATCHED AND (S.customer_name <> T.customer_name OR S.customer_state <> T.customer_state OR S.customer_gender <> T.customer_gender OR S.customer_status <> T.customer_status)
        THEN UPDATE SET T.validity_end_date = @dt_end
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date)
             VALUES (S.id_customer, S.customer_name, S.customer_state, S.customer_gender, S.customer_status, @dt_start, NULL)
    OUTPUT $ACTION AS action, S.id_customer, S.customer_name, S.customer_state, S.customer_gender, S.customer_status, @dt_start AS validity_start_date, NULL AS validity_end_date
) AS O WHERE O.action = 'UPDATE';

-- Check the modified customers to verify each customer's history. Date fields have been updated.
SELECT * FROM Dimensional..dim_customer WHERE id_customer BETWEEN 1 AND 5;

-- Verify that the customers in the January fact load are pointing to the old SKs of customers 1, 2, 3, and 5
SELECT *
FROM Dimensional..fact_sales f
INNER JOIN Dimensional..dim_customer c ON f.customer_key = c.customer_key
WHERE c.id_customer BETWEEN 1 AND 5;

-- LOAD ONLY THE MONTH OF FEBRUARY INTO fact_sales
INSERT INTO Dimensional..fact_sales (seller_key, customer_key, product_key, time_key, quantity, unit_price, total_price, discount)
SELECT
    vdd.seller_key,
    c.customer_key,
    p.product_key,
    t.time_key,
    iv.quantity,
    iv.unit_price,
    iv.total_price,
    iv.discount
FROM Relational..sales v
INNER JOIN Dimensional..dim_seller vdd   ON v.id_seller   = vdd.id_seller   AND vdd.validity_end_date IS NULL
INNER JOIN Relational..sale_items iv     ON v.id_sale     = iv.id_sale
INNER JOIN Dimensional..dim_customer c   ON v.id_customer = c.id_customer   AND c.validity_end_date   IS NULL
INNER JOIN Dimensional..dim_product p    ON iv.id_product = p.id_product    AND p.validity_end_date   IS NULL
INNER JOIN Dimensional..dim_time t       ON v.sale_date   = t.time_date
WHERE MONTH(v.sale_date) = 2; -- FEBRUARY

-- The January fact load customers are still pointing to the old SKs of customers 1 to 5.
-- In February only customer 5 made purchases. The fact records already point to the customer's latest SK.
SELECT *
FROM Dimensional..fact_sales f
INNER JOIN Dimensional..dim_customer c ON f.customer_key = c.customer_key
WHERE c.id_customer BETWEEN 1 AND 5;

-- LOAD ONLY THE MONTH OF MARCH INTO fact_sales
INSERT INTO Dimensional..fact_sales (seller_key, customer_key, product_key, time_key, quantity, unit_price, total_price, discount)
SELECT
    vdd.seller_key,
    c.customer_key,
    p.product_key,
    t.time_key,
    iv.quantity,
    iv.unit_price,
    iv.total_price,
    iv.discount
FROM Relational..sales v
INNER JOIN Dimensional..dim_seller vdd   ON v.id_seller   = vdd.id_seller   AND vdd.validity_end_date IS NULL
INNER JOIN Relational..sale_items iv     ON v.id_sale     = iv.id_sale
INNER JOIN Dimensional..dim_customer c   ON v.id_customer = c.id_customer   AND c.validity_end_date   IS NULL
INNER JOIN Dimensional..dim_product p    ON iv.id_product = p.id_product    AND p.validity_end_date   IS NULL
INNER JOIN Dimensional..dim_time t       ON v.sale_date   = t.time_date
WHERE MONTH(v.sale_date) = 3; -- MARCH

-- In March none of the customers we are mapping (1 to 5) made purchases.
SELECT *
FROM Dimensional..fact_sales f
INNER JOIN Dimensional..dim_customer c ON f.customer_key = c.customer_key
INNER JOIN Dimensional..dim_time t     ON f.time_key     = t.time_key
WHERE c.id_customer BETWEEN 1 AND 5 AND t.time_month = 3;

-- A plan change is made for customer 3
UPDATE Relational..customers
SET customer_status = 'Platinum'
WHERE id_customer = 3;

-- LOAD CUSTOMER DATA. WILL ONLY PROCESS HISTORY ON MODIFIED RECORDS (CUSTOMER 3)
INSERT INTO Dimensional..dim_customer (id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date)
SELECT id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date
FROM (
    MERGE Dimensional..dim_customer AS T
    USING Relational..customers AS S
    ON (T.id_customer = S.id_customer AND T.validity_end_date IS NULL)
    WHEN MATCHED AND (S.customer_name <> T.customer_name OR S.customer_state <> T.customer_state OR S.customer_gender <> T.customer_gender OR S.customer_status <> T.customer_status)
        THEN UPDATE SET T.validity_end_date = @dt_end
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (id_customer, customer_name, customer_state, customer_gender, customer_status, validity_start_date, validity_end_date)
             VALUES (S.id_customer, S.customer_name, S.customer_state, S.customer_gender, S.customer_status, @dt_start, NULL)
    OUTPUT $ACTION AS action, S.id_customer, S.customer_name, S.customer_state, S.customer_gender, S.customer_status, @dt_start AS validity_start_date, NULL AS validity_end_date
) AS O WHERE O.action = 'UPDATE';

-- Check the modified customers to verify each customer's history. Date fields have been updated.
SELECT * FROM Dimensional..dim_customer WHERE id_customer BETWEEN 1 AND 5;

-- LOAD ALL REMAINING MONTHS INTO fact_sales
INSERT INTO Dimensional..fact_sales (seller_key, customer_key, product_key, time_key, quantity, unit_price, total_price, discount)
SELECT
    vdd.seller_key,
    c.customer_key,
    p.product_key,
    t.time_key,
    iv.quantity,
    iv.unit_price,
    iv.total_price,
    iv.discount
FROM Relational..sales v
INNER JOIN Dimensional..dim_seller vdd   ON v.id_seller   = vdd.id_seller   AND vdd.validity_end_date IS NULL
INNER JOIN Relational..sale_items iv     ON v.id_sale     = iv.id_sale
INNER JOIN Dimensional..dim_customer c   ON v.id_customer = c.id_customer   AND c.validity_end_date   IS NULL
INNER JOIN Dimensional..dim_product p    ON iv.id_product = p.id_product    AND p.validity_end_date   IS NULL
INNER JOIN Dimensional..dim_time t       ON v.sale_date   = t.time_date
WHERE MONTH(v.sale_date) > 3;

-- Check all purchases from the customers we are mapping (1 to 5).
-- We verify that there were purchases with the old SK and now there are purchases with the latest SK.
SELECT *
FROM Dimensional..fact_sales f
INNER JOIN Dimensional..dim_customer c ON f.customer_key = c.customer_key
INNER JOIN Dimensional..dim_time t     ON f.time_key     = t.time_key
WHERE c.id_customer BETWEEN 1 AND 5;
