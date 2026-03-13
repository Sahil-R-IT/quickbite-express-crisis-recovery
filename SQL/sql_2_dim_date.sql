-- Create dim_date using DISTINCT order dates from fact_orders
SELECT DISTINCT
    CAST(order_timestamp AS date)                                      AS [date],
    CONVERT(int, CONVERT(char(8), CAST(order_timestamp AS date), 112)) AS date_key,      -- YYYYMMDD
    DATEPART(year,  CAST(order_timestamp AS date))                     AS [year],
    DATEPART(month, CAST(order_timestamp AS date))                     AS [month],
    DATENAME(month, CAST(order_timestamp AS date))                     AS month_name,
    DATEFROMPARTS(
        DATEPART(year,  CAST(order_timestamp AS date)),
        DATEPART(month, CAST(order_timestamp AS date)),
        1
    )                                                                  AS month_start_date,
    CONVERT(char(7), CAST(order_timestamp AS date), 120)               AS year_month,    -- YYYY-MM
    DATEPART(weekday, CAST(order_timestamp AS date))                   AS day_of_week,
    DATENAME(weekday, CAST(order_timestamp AS date))                   AS day_name,
    CASE WHEN DATENAME(weekday, CAST(order_timestamp AS date)) IN ('Saturday','Sunday')
         THEN 1 ELSE 0 END                                             AS is_weekend,
    CASE
        WHEN CAST(order_timestamp AS date) < '2025-06-01' THEN 'pre'
        WHEN CAST(order_timestamp AS date) < '2025-07-01' THEN 'crisis'
        ELSE 'post'
    END                                                                AS phase
INTO dim_date
FROM fact_orders;

select * from dim_restaurant;

select * from fact_ratings
where sentiment_score = 0.7 ;

SELECT *
FROM fact_orders o
JOIN dim_date d
  ON d.[date] = CAST(o.order_timestamp AS date);