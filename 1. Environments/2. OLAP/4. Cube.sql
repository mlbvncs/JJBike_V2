SELECT
    dc.customer_name,
    dc.customer_state,
    dc.customer_gender,
    dc.customer_status,
    fs.quantity,
    fs.unit_price,
    fs.total_price,
    fs.discount,
    dp.product_name,
    dt.time_date,
    dt.time_day,
    dt.time_month,
    dt.time_year,
    dt.time_quarter,
    dv.seller_name
INTO Dimensional..sales_cube
FROM Dimensional..fact_sales fs
INNER JOIN Dimensional..dim_customer dc ON fs.customer_key = dc.customer_key
INNER JOIN Dimensional..dim_product  dp ON fs.product_key  = dp.product_key
INNER JOIN Dimensional..dim_time     dt ON fs.time_key     = dt.time_key
INNER JOIN Dimensional..dim_seller   dv ON fs.seller_key   = dv.seller_key;
