IF OBJECT_ID('Dimensional..kpi', 'U') IS NOT NULL
    DROP TABLE Dimensional..kpi;
GO

SELECT
    dt.time_month AS month,
    SUM(fs.total_price) AS total_revenue,
    CAST(CASE dt.time_month
        WHEN 1  THEN 220000
        WHEN 2  THEN 220000
        WHEN 3  THEN 230000
        WHEN 4  THEN 235000
        WHEN 5  THEN 240000
        WHEN 6  THEN 250000
        WHEN 7  THEN 255000
        WHEN 8  THEN 260000
        WHEN 9  THEN 262500
        WHEN 10 THEN 265000
        WHEN 11 THEN 267000
        WHEN 12 THEN 270000
    END AS NUMERIC(18,2)) AS target
INTO Dimensional..kpi
FROM Dimensional..fact_sales fs
INNER JOIN Dimensional..dim_time dt ON fs.time_key = dt.time_key
GROUP BY dt.time_month
ORDER BY dt.time_month ASC;
GO

-- Final query for data validation
SELECT * FROM Dimensional..kpi;
GO
