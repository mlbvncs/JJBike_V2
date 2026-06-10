DECLARE @dt_end   DATETIME = GETDATE();              
DECLARE @dt_start DATETIME = DATEADD(MILLISECOND, 3, @dt_end); 

-- ====================================================================================
-- 1. LOAD DIMENSIONS (SCD TYPE 2 + HARD DELETE DETECTION)
-- ====================================================================================

-- LOAD CUSTOMER DATA (INCLUDES DELETION SCAN)
UPDATE T
SET T.validity_end_date = @dt_end
FROM Dimensional..dim_customer T
WHERE T.validity_end_date IS NULL 
  AND T.id_customer NOT IN (SELECT id_customer FROM Relational..customers);

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


-- LOAD PRODUCT DATA (INCLUDES DELETION SCAN)
UPDATE T
SET T.validity_end_date = @dt_end
FROM Dimensional..dim_product T
WHERE T.validity_end_date IS NULL 
  AND T.id_product NOT IN (SELECT id_product FROM Relational..products);

INSERT INTO Dimensional..dim_product (id_product, product_name, validity_start_date, validity_end_date)
SELECT id_product, product_name, validity_start_date, validity_end_date
FROM (
    MERGE Dimensional..dim_product AS T
    USING Relational..products AS S
    ON (T.id_product = S.id_product AND T.validity_end_date IS NULL)
    WHEN MATCHED AND (S.product_name <> T.product_name)
        THEN UPDATE SET T.validity_end_date = @dt_end
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (id_product, product_name, validity_start_date, validity_end_date)
             VALUES (S.id_product, S.product_name, @dt_start, NULL)
    OUTPUT $ACTION AS action, S.id_product, S.product_name, @dt_start AS validity_start_date, NULL AS validity_end_date
) AS O WHERE O.action = 'UPDATE';


-- LOAD SELLER DATA (INCLUDES DELETION SCAN)
UPDATE T
SET T.validity_end_date = @dt_end
FROM Dimensional..dim_seller T
WHERE T.validity_end_date IS NULL 
  AND T.id_seller NOT IN (SELECT id_seller FROM Relational..sellers);

INSERT INTO Dimensional..dim_seller (id_seller, seller_name, validity_start_date, validity_end_date)
SELECT id_seller, seller_name, validity_start_date, validity_end_date
FROM (
    MERGE Dimensional..dim_seller AS T
    USING Relational..sellers AS S
    ON (T.id_seller = S.id_seller AND T.validity_end_date IS NULL)
    WHEN MATCHED AND (S.seller_name <> T.seller_name)
        THEN UPDATE SET T.validity_end_date = @dt_end
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (id_seller, seller_name, validity_start_date, validity_end_date)
             VALUES (S.id_seller, S.seller_name, @dt_start, NULL)
    OUTPUT $ACTION AS action, S.id_seller, S.seller_name, @dt_start AS validity_start_date, NULL AS validity_end_date
) AS O WHERE O.action = 'UPDATE';


-- ====================================================================================
-- 2. FACT LOADS USING TEMPORAL JOINS (PREVENTS BLURRED FACTS)
-- ====================================================================================

-- ONLY THE MONTH OF JANUARY IS LOADED INTO FACT_SALES
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
INNER JOIN Relational..sale_items iv     ON v.id_sale     = iv.id_sale
INNER JOIN Dimensional..dim_seller vdd   ON v.id_seller   = vdd.id_seller   AND v.sale_date >= vdd.validity_start_date AND (v.sale_date <= vdd.validity_end_date OR vdd.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_customer c   ON v.id_customer = c.id_customer   AND v.sale_date >= c.validity_start_date   AND (v.sale_date <= c.validity_end_date OR c.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_product p    ON iv.id_product = p.id_product    AND v.sale_date >= p.validity_start_date   AND (v.sale_date <= p.validity_end_date OR p.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_time t       ON v.sale_date   = t.time_date
WHERE MONTH(v.sale_date) = 1;


-- A PLAN CHANGE IS BEING MADE FOR CUSTOMERS WITH IDs 1 TO 5
UPDATE Relational..customers
SET customer_status = 'Gold'
WHERE id_customer BETWEEN 1 AND 5;


-- LOAD CUSTOMER DATA
UPDATE T
SET T.validity_end_date = @dt_end
FROM Dimensional..dim_customer T
WHERE T.validity_end_date IS NULL 
  AND T.id_customer NOT IN (SELECT id_customer FROM Relational..customers);

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


-- CHECK THE MODIFIED CUSTOMERS
SELECT * FROM Dimensional..dim_customer WHERE id_customer BETWEEN 1 AND 5;


-- VERIFY JANUARY FACT LOAD SURROGATES
SELECT *
FROM Dimensional..fact_sales f
INNER JOIN Dimensional..dim_customer c ON f.customer_key = c.customer_key
WHERE c.id_customer BETWEEN 1 AND 5;


-- ONLY THE MONTH OF FEBRUARY IS LOADED INTO FACT_SALES
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
INNER JOIN Relational..sale_items iv     ON v.id_sale     = iv.id_sale
INNER JOIN Dimensional..dim_seller vdd   ON v.id_seller   = vdd.id_seller   AND v.sale_date >= vdd.validity_start_date AND (v.sale_date <= vdd.validity_end_date OR vdd.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_customer c   ON v.id_customer = c.id_customer   AND v.sale_date >= c.validity_start_date   AND (v.sale_date <= c.validity_end_date OR c.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_product p    ON iv.id_product = p.id_product    AND v.sale_date >= p.validity_start_date   AND (v.sale_date <= p.validity_end_date OR p.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_time t       ON v.sale_date   = t.time_date
WHERE MONTH(v.sale_date) = 2;


-- CHECK BALANCED SURROGATES (JANUARY VS FEBRUARY)
SELECT *
FROM Dimensional..fact_sales f
INNER JOIN Dimensional..dim_customer c ON f.customer_key = c.customer_key
WHERE c.id_customer BETWEEN 1 AND 5;


-- ONLY THE MONTH OF MARCH IS LOADED INTO FACT_SALES
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
INNER JOIN Relational..sale_items iv     ON v.id_sale     = iv.id_sale
INNER JOIN Dimensional..dim_seller vdd   ON v.id_seller   = vdd.id_seller   AND v.sale_date >= vdd.validity_start_date AND (v.sale_date <= vdd.validity_end_date OR vdd.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_customer c   ON v.id_customer = c.id_customer   AND v.sale_date >= c.validity_start_date   AND (v.sale_date <= c.validity_end_date OR c.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_product p    ON iv.id_product = p.id_product    AND v.sale_date >= p.validity_start_date   AND (v.sale_date <= p.validity_end_date OR p.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_time t       ON v.sale_date   = t.time_date
WHERE MONTH(v.sale_date) = 3;


-- VERIFY MARCH PURCHASES
SELECT *
FROM Dimensional..fact_sales f
INNER JOIN Dimensional..dim_customer c ON f.customer_key = c.customer_key
INNER JOIN Dimensional..dim_time t     ON f.time_key     = t.time_key
WHERE c.id_customer BETWEEN 1 AND 5 AND t.time_month = 3;


-- MAKE A PLAN CHANGE FOR CUSTOMER 3
UPDATE Relational..customers
SET customer_status = 'Platinum'
WHERE id_customer = 3;


-- LOAD CUSTOMER DATA
UPDATE T
SET T.validity_end_date = @dt_end
FROM Dimensional..dim_customer T
WHERE T.validity_end_date IS NULL 
  AND T.id_customer NOT IN (SELECT id_customer FROM Relational..customers);

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


-- CHECK HISTORY FOR ALL TRACKED ENTITIES
SELECT * FROM Dimensional..dim_customer WHERE id_customer BETWEEN 1 AND 5;


-- LOAD ALL REMAINING MONTHS
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
INNER JOIN Relational..sale_items iv     ON v.id_sale     = iv.id_sale
INNER JOIN Dimensional..dim_seller vdd   ON v.id_seller   = vdd.id_seller   AND v.sale_date >= vdd.validity_start_date AND (v.sale_date <= vdd.validity_end_date OR vdd.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_customer c   ON v.id_customer = c.id_customer   AND v.sale_date >= c.validity_start_date   AND (v.sale_date <= c.validity_end_date OR c.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_product p    ON iv.id_product = p.id_product    AND v.sale_date >= p.validity_start_date   AND (v.sale_date <= p.validity_end_date OR p.validity_end_date IS NULL)
INNER JOIN Dimensional..dim_time t       ON v.sale_date   = t.time_date
WHERE MONTH(v.sale_date) > 3;


-- FINAL AUDIT CHECK
SELECT *
FROM Dimensional..fact_sales f
INNER JOIN Dimensional..dim_customer c ON f.customer_key = c.customer_key
INNER JOIN Dimensional..dim_time t     ON f.time_key     = t.time_key
WHERE c.id_customer BETWEEN 1 AND 5;