-- 1. Set the date format and the range of dates to generate
SET DATEFORMAT dmy;
GO

DECLARE @start_date DATETIME = '01/01/1970';
DECLARE @end_date   DATETIME = '31/12/2030';

-- 2. Generate and insert data using a recursive CTE (no WHILE or loops needed)
WITH date_sequence AS (
    -- Anchor: start at the initial date
    SELECT @start_date AS generated_date
    UNION ALL
    -- Recursion: add 1 day at a time until the end date is reached
    SELECT DATEADD(day, 1, generated_date)
    FROM date_sequence
    WHERE generated_date < @end_date
)
INSERT INTO Dimensional..dim_time (time_date, time_day, time_month, time_year, time_weekday, time_quarter)
SELECT
    generated_date          AS time_date,
    DAY(generated_date)     AS time_day,
    MONTH(generated_date)   AS time_month,
    YEAR(generated_date)    AS time_year,
    DATEPART(weekday,  generated_date) AS time_weekday,
    DATEPART(quarter,  generated_date) AS time_quarter
FROM date_sequence
OPTION (MAXRECURSION 0); -- Allows recursion beyond the default 100-row limit
GO
