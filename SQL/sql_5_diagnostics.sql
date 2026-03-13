-- Diagnostic Layer

use Quitebit;

-- Behaviour per active day(1 day = 1 order)
select
    phase,
    sum(cast(non_cancel_orders as float)) 
      / nullif(sum(cast(active_customers_non_cancel as float)), 0) 
      as orders_per_active_customer
from daily_summary
group by phase
order by phase;


-- phase per each active customer placed order on average

with base as (
    select
        d.phase,
        o.order_id,
        o.customer_id,
        o.total_amount
    from fact_orders as o
    inner join dim_date as d
        on d.[date] = cast(o.order_timestamp as date)
    where o.is_cancelled = 'N'
)
select
    phase,
    count(distinct customer_id) as active_customers,
    count(distinct order_id)    as non_cancel_orders,

    count(distinct order_id) * 1.0
      / nullif(count(distinct customer_id), 0) as frequency,

    sum(total_amount) as revenue,

    sum(total_amount) * 1.0
      / nullif(count(distinct order_id), 0) as aov
from base
group by phase
order by phase;


-- customer finding(inlcuding cancel and noncancel order)

with pre_phase as (
    select distinct o.customer_id,d.phase
    from fact_orders as o
    inner join dim_date as d
        on d.[date] = cast(o.order_timestamp as date)
    where d.phase = 'pre'
), post_phase as (
    select distinct o.customer_id,d.phase
    from fact_orders as o
    inner join dim_date as d
        on d.[date] = cast(o.order_timestamp as date)
    where d.phase = 'post'
), crisis_phase as (
    select
    distinct o.customer_id,
    d.phase
    from fact_orders as o
    inner join dim_date as d
        on d.[date] = cast(o.order_timestamp as date)
    where d.phase = 'crisis'
), pre_and_crisis as (
    select p.customer_id
    from pre_phase as p
    inner join crisis_phase as c on p.customer_id = c.customer_id
)
select
    count(*) as pre_customer_total,
    sum(case when c.customer_id is null then 1 else 0 end) as pre_never_ordered_in_crisis,
    cast(100.0 * sum(case when c.customer_id is null then 1 else 0 end) 
        / count(*) as decimal(10,2)) as pct_pre_missing_in_crisis,
    SUM(CASE WHEN c.customer_id IS NOT NULL THEN 1 ELSE 0 END) AS customer_pre_and_crisis
from pre_phase as p
left join crisis_phase as c
    on p.customer_id = c.customer_id;

-- weekly table

with weekly_orders as (
    select
        d.phase,
        cast(dateadd(week, datediff(week, 0, d.[date]), 0) as date) as week_start_date,
        count(distinct o.order_id) as weekly_order,
        count(distinct o.customer_id) as weekly_active_customer,
        count(distinct case when is_cancelled = 'Y' then o.order_id end) as weekly_cancel_order,
        count(distinct o.restaurant_id) as weekly_active_restaurant
    from fact_orders as o
    inner join dim_date as d
        on d.[date] = cast(o.order_timestamp as date)
    group by dateadd(week, datediff(week, 0, d.[date]), 0), d.phase
),
weekly_rating as (
    select
        cast(dateadd(week, datediff(week, 0, d.[date]), 0) as date) as week_start_date,
        avg(cast(r.rating as float)) as avg_weekly_rating
    from fact_ratings as r
    inner join fact_orders as o
        on o.order_id = r.order_id
    inner join dim_date as d
        on d.[date] = cast(o.order_timestamp as date)
    group by dateadd(week, datediff(week, 0, d.[date]), 0)
), 
weekly_deliverytime as (
    select
        cast(dateadd(week, datediff(week,0,  d.[date]), 0) as date) as week_start_date,
        avg(cast(dp.actual_delivery_time_mins as float)) as avg_weekly_actual_time,
        avg(cast(dp.expected_delivery_time_mins as float)) as avg_weekly_expected_time
        from fact_delivery_performance as dp
        inner join fact_orders as o
            on o.order_id = dp.order_id
        inner join dim_date as d
            on d.[date] = cast(o.order_timestamp as date)
        group by dateadd(week, datediff(week,0,d.[date]), 0)
)
select 
    wo.*,
    cast(wo.weekly_cancel_order as float) / nullif(wo.weekly_order, 0) as cancellation_rate,
    wr.avg_weekly_rating,
    wd.avg_weekly_actual_time,
    wd.avg_weekly_expected_time,
    (wd.avg_weekly_actual_time - wd.avg_weekly_expected_time) as avg_weekly_delay_min
from weekly_orders as wo
left join weekly_rating as wr
    on wo.week_start_date = wr.week_start_date
left join weekly_deliverytime as wd
    on wo.week_start_date = wd.week_start_date
order by wo.week_start_date;

-- may customer retention rate

with may_customers as (
    select distinct o.customer_id
    from fact_orders o
    where o.order_timestamp >= '2025-05-01'
      and o.order_timestamp <  '2025-06-01'
),
june_experience as (
    select
        o.customer_id,
        max(case 
              when (cast(dp.actual_delivery_time_mins as float) 
                    - cast(dp.expected_delivery_time_mins as float)) > 15 
              then 1 else 0 end) as high_delay_flag,
        max(case when o.is_cancelled = 'y' then 1 else 0 end) as cancelled_flag
    from fact_orders o
    left join fact_delivery_performance dp
        on o.order_id = dp.order_id
    where o.order_timestamp >= '2025-06-01'
      and o.order_timestamp <  '2025-07-01'
    group by o.customer_id
),
july_retention as (
    select distinct o.customer_id, 1 as retained_flag
    from fact_orders o
    where o.order_timestamp >= '2025-07-01'
      and o.order_timestamp <  '2025-08-01'
),
customer_flags as (
    select
        'may_2025' as cohort_name, -- Added cohort identifier
        m.customer_id,
        isnull(j.high_delay_flag, 0) as high_delay_flag,
        isnull(j.cancelled_flag, 0) as cancelled_flag,
        isnull(r.retained_flag, 0) as retained_flag
    from may_customers m
    left join june_experience j
        on m.customer_id = j.customer_id
    left join july_retention r
        on m.customer_id = r.customer_id
)
select
    cohort_name, -- Grouping by cohort for easier merging later
    high_delay_flag,
    cancelled_flag,
    count(*) as total_customers,
    sum(retained_flag) as retained_customers, -- Essential for proportion tests
    avg(cast(retained_flag as float)) as retention_rate
from customer_flags
group by cohort_name, high_delay_flag, cancelled_flag
order by high_delay_flag desc, cancelled_flag desc;

-- lower rating rate with retention rate

with may_customers as (
    select
        o.customer_id,
        count(*) as may_order_count
    from fact_orders o
    where o.order_timestamp >= '2025-05-01'
      and o.order_timestamp <  '2025-06-01'
      and o.is_cancelled = 'n'
    group by o.customer_id
),

june_experience as (
    select
        o.customer_id,

        -- june order activity flags
        max(case when o.is_cancelled = 'n' then 1 else 0 end) as june_non_cancel_order_flag,
        max(case when o.is_cancelled = 'y' then 1 else 0 end) as june_cancelled_flag,

        -- ops experience flags
        max(case
              when (cast(dp.actual_delivery_time_mins as float)
                    - cast(dp.expected_delivery_time_mins as float)) > 10
              then 1 else 0 end) as delay_diff_flag,
        max(case
              when cast(dp.actual_delivery_time_mins as float) > 45
              then 1 else 0 end) as long_delivery_flag,

        -- trust/quality signal: low rating (<=2) on a non-cancelled order
        max(case
              when o.is_cancelled = 'n' and r.rating <= 2
              then 1 else 0 end) as low_rating_flag

    from fact_orders o
    left join fact_delivery_performance dp
        on o.order_id = dp.order_id
    left join fact_ratings r
        on o.order_id = r.order_id
    where o.order_timestamp >= '2025-06-01'
      and o.order_timestamp <  '2025-07-01'
    group by o.customer_id
),

july_retention as (
    select distinct
        o.customer_id,
        1 as retained_flag
    from fact_orders o
    where o.order_timestamp >= '2025-07-01'
      and o.order_timestamp <  '2025-08-01'
      and o.is_cancelled = 'n'
),

customer_flags as (
    select
        m.customer_id,
        m.may_order_count,
        isnull(j.low_rating_flag, 0) as low_rating_flag,
        isnull(r.retained_flag, 0) as retained_flag
    from may_customers m
    left join june_experience j
        on m.customer_id = j.customer_id
    left join july_retention r
        on m.customer_id = r.customer_id
)

select
    low_rating_flag,
    count(*) as customers,
    sum(retained_flag) as retained_count,
    avg(cast(retained_flag as float)) as retention_rate,
    avg(cast(may_order_count as float)) as avg_may_order_count
from customer_flags
group by low_rating_flag
order by low_rating_flag desc;

-- segment damage

with orders as (
    select
        o.customer_id as customer_id,
        cast(o.order_timestamp as date) as order_date
    from fact_orders as o
    where o.is_cancelled = 'N'
),
first_order as (
    select customer_id, min(order_date) as first_order_date
    from orders
    group by customer_id
),
order_with_phase as (
    select
        d.phase,
        o.order_date,
        o.customer_id,
        case   
            when o.order_date = f.first_order_date then 1 else 0
        end as is_new_customer
        from orders as o
        left join first_order as f
            on o.customer_id = f.customer_id
        left join dim_date as d
            on d.[date] = o.order_date
)
select
    phase,
    count(distinct case when is_new_customer = 1 then customer_id end) as new_customer,
    count(distinct case when is_new_customer = 0 then customer_id end) as returning_customer
from order_with_phase
group by phase
order by phase;

-- may frequency retention test

with may_orders as (
    select
        o.customer_id,
        count(*) as may_order
        from fact_orders as o
        where o.order_timestamp >= '2025-05-01'
            and o.order_timestamp < '2025-06-01'
            and o.is_cancelled = 'N'
        group by o.customer_id
),
may_cohort as (
    select
        customer_id,
        may_order,
        case    
            when may_order = 1 then '1_order'
            when may_order = 2 then '2_order'
            else '3+_order'
        end as frequency_bucket
    from may_orders
),
july_retention as (
    select distinct o.customer_id,
    1 as retained_flag
    from fact_orders as o
    where o.order_timestamp >= '2025-07-01'
        and o.order_timestamp < '2025-08-01'
        and o.is_cancelled = 'N'
)
select
        mc.frequency_bucket,
        count(*) as customer,
        avg(Cast(isnull(jr.retained_flag, 0) as float)) as retention_rate
    from may_cohort as mc
    left join july_retention as jr
        on mc.customer_id = jr.customer_id
    group by mc.frequency_bucket
    order by mc.frequency_bucket;

-- tier wise revnue and order with phase
with pre_rest as (
    select
        o.restaurant_id as restaurant_id,
        sum(coalesce(o.total_amount, 0)) as pre_revenue,
        count(*) as pre_orders
        from fact_orders as o
        inner join dim_date as d
            on d.[date] = cast(o.order_timestamp as date)
        where d.phase = 'pre'
            and o.is_cancelled = 'N'
        group by o.restaurant_id
),
ranked as (
    select
        restaurant_id,
        pre_revenue,
        pre_orders,
        ntile(10) over (order by pre_revenue desc) as decile
    from pre_rest
), 
tiered as (
    select
        restaurant_id,
        case    
            when decile = 1 then 'Top_10%'
            when decile in (2,3) then 'Next_20%'
            else 'Bottom_70%'
        end as restaurant_tier
        from ranked
),
all_phase as (
    select
        o.restaurant_id,
        d.phase,
        sum(coalesce(o.total_amount, 0)) as revenue,
        count(*) as orders
        from fact_orders as o
        inner join dim_date as d
            on d.[date] = cast(o.order_timestamp as date)
        where o.is_cancelled = 'N'
        group by o.restaurant_id, d.phase
)
select
    t.restaurant_tier,
    a.phase,
    sum(a.orders) as orders,
    sum(a.revenue) as revenue
from tiered as t
left join all_phase as a
    on t.restaurant_id = a.restaurant_id
group by a.phase, t.restaurant_tier
order by 
    case t.restaurant_tier
        when 'Top_10%' then 1
        when 'Next_20%' then 2
        else 3
    end,
    case  a.phase
        when 'pre' then 1
        when 'crisis' then 2
        else 3
    end;

--  top 15 rest in pre
WITH pre_top AS (
    SELECT TOP 15
        o.restaurant_id,
        SUM(COALESCE(o.total_amount,0)) AS pre_revenue,
        COUNT(*) AS pre_orders
    FROM fact_orders o
    JOIN dim_date d
      ON d.[date] = CAST(o.order_timestamp AS date)
    WHERE d.phase = 'pre'
      AND o.is_cancelled = 'n'
    GROUP BY o.restaurant_id
    ORDER BY SUM(COALESCE(o.total_amount,0)) DESC
)
SELECT
    r.restaurant_id,
    r.restaurant_name,
    r.city,
    pt.pre_orders,
    pt.pre_revenue
FROM pre_top pt
JOIN dim_restaurant r
  ON r.restaurant_id = pt.restaurant_id
ORDER BY pt.pre_revenue DESC;


-- compare top 15 rest to crisi and post
WITH pre_top AS (
    SELECT TOP 15
        o.restaurant_id,
        SUM(COALESCE(o.total_amount,0)) AS pre_revenue
    FROM fact_orders o
    JOIN dim_date d
      ON d.[date] = CAST(o.order_timestamp AS date)
    WHERE d.phase = 'pre'
      AND o.is_cancelled = 'n'
    GROUP BY o.restaurant_id
    ORDER BY SUM(COALESCE(o.total_amount,0)) DESC
),
phase_perf AS (
    SELECT
        o.restaurant_id,
        d.phase,
        COUNT(*) AS orders,
        SUM(COALESCE(o.total_amount,0)) AS revenue
    FROM fact_orders o
    JOIN dim_date d
      ON d.[date] = CAST(o.order_timestamp AS date)
    WHERE o.is_cancelled = 'n'
      AND d.phase IN ('pre','crisis','post')
    GROUP BY o.restaurant_id, d.phase
)
SELECT
    r.restaurant_id,
    r.restaurant_name,
    r.city,
    p.phase,
    p.orders,
    p.revenue
FROM pre_top t
JOIN dim_restaurant r
  ON r.restaurant_id = t.restaurant_id
LEFT JOIN phase_perf p
  ON p.restaurant_id = t.restaurant_id
ORDER BY
    t.pre_revenue DESC,
    CASE p.phase WHEN 'pre' THEN 1 WHEN 'crisis' THEN 2 ELSE 3 END;


-- city phase drop table
WITH city_phase AS (
    SELECT
        r.city,
        d.phase,
        COUNT(*) AS orders,
        SUM(COALESCE(o.total_amount,0)) AS revenue,
        COUNT(DISTINCT o.customer_id) AS active_customers,
        COUNT(DISTINCT o.restaurant_id) AS active_restaurants
    FROM fact_orders o
    JOIN dim_date d
      ON d.[date] = CAST(o.order_timestamp AS date)
    JOIN dim_restaurant r
      ON r.restaurant_id = o.restaurant_id
    WHERE o.is_cancelled = 'n'
      AND d.phase IN ('pre','crisis','post')
    GROUP BY r.city, d.phase
)
SELECT *
FROM city_phase
ORDER BY city, 
         CASE phase WHEN 'pre' THEN 1 WHEN 'crisis' THEN 2 ELSE 3 END;

/* city_revenue_df: city x phase metrics for python/bi */

with city_phase as (
    select
        r.city,
        d.phase,
        count(*) as orders,
        cast(sum(coalesce(try_cast(o.total_amount as decimal(18,2)), 0)) as decimal(18,2)) as revenue,
        count(distinct o.customer_id) as active_customers,
        count(distinct o.restaurant_id) as active_restaurants,

        count(distinct case when r.is_active = 1 then o.restaurant_id end) as active_partner_restaurants,

        avg(case when r.is_active = 1 then
            case 
                when r.avg_prep_time_min = '0-15'  then 7.5
                when r.avg_prep_time_min = '16-25' then 20.5
                when r.avg_prep_time_min = '26-40' then 33.0
                when r.avg_prep_time_min = '>40'   then 45.0
                else try_cast(r.avg_prep_time_min as float)
            end
        end) as avg_prep_time_active_restaurants

    from fact_orders o
    join dim_date d
      on d.[date] = cast(o.order_timestamp as date)
    join dim_restaurant r
      on r.restaurant_id = o.restaurant_id
    where o.is_cancelled = 'n'
      and d.phase in ('pre', 'crisis', 'post')
    group by r.city, d.phase
),
phase_totals as (
    select
        phase,
        sum(revenue) as total_phase_revenue
    from city_phase
    group by phase
)
select
    cp.city,
    cp.phase,
    cp.orders,
    cp.revenue,
    cp.active_customers,
    cp.active_restaurants,
    cp.active_partner_restaurants,
    cp.avg_prep_time_active_restaurants,

    cast(cp.orders * 1.0 / nullif(cp.active_customers, 0) as decimal(10,4)) as frequency,
    cast(cp.revenue * 1.0 / nullif(cp.orders, 0) as decimal(10,2)) as aov,
    cast(cp.revenue * 1.0 / nullif(pt.total_phase_revenue, 0) as decimal(10,6)) as revenue_share_in_phase
from city_phase cp
join phase_totals pt
  on cp.phase = pt.phase
order by
    cp.city,
case cp.phase when 'pre' then 1 when 'crisis' then 2 else 3 end;


/* city_revenue_wide_df: one row per city with drop/recovery % */

WITH city_phase AS (
    SELECT
        r.city,
        d.phase,
        SUM(COALESCE(o.total_amount, 0)) AS revenue,
        COUNT(*) AS orders,
        COUNT(DISTINCT o.customer_id) AS active_customers,
        COUNT(DISTINCT o.restaurant_id) AS active_restaurants
    FROM fact_orders o
    JOIN dim_date d
      ON d.[date] = CAST(o.order_timestamp AS date)
    JOIN dim_restaurant r
      ON r.restaurant_id = o.restaurant_id
    WHERE o.is_cancelled = 'n'
      AND d.phase IN ('pre','crisis','post')
    GROUP BY r.city, d.phase
),
p AS (
    SELECT
        city,
        MAX(CASE WHEN phase='pre' THEN revenue END) AS pre_revenue,
        MAX(CASE WHEN phase='crisis' THEN revenue END) AS crisis_revenue,
        MAX(CASE WHEN phase='post' THEN revenue END) AS post_revenue,

        MAX(CASE WHEN phase='pre' THEN orders END) AS pre_orders,
        MAX(CASE WHEN phase='crisis' THEN orders END) AS crisis_orders,
        MAX(CASE WHEN phase='post' THEN orders END) AS post_orders,

        MAX(CASE WHEN phase='pre' THEN active_customers END) AS pre_active_customers,
        MAX(CASE WHEN phase='crisis' THEN active_customers END) AS crisis_active_customers,
        MAX(CASE WHEN phase='post' THEN active_customers END) AS post_active_customers,

        MAX(CASE WHEN phase='pre' THEN active_restaurants END) AS pre_active_restaurants,
        MAX(CASE WHEN phase='crisis' THEN active_restaurants END) AS crisis_active_restaurants,
        MAX(CASE WHEN phase='post' THEN active_restaurants END) AS post_active_restaurants
    FROM city_phase
    GROUP BY city
)
SELECT
    city,
    pre_revenue, crisis_revenue, post_revenue,
    pre_orders, crisis_orders, post_orders,
    pre_active_customers, crisis_active_customers, post_active_customers,
    pre_active_restaurants, crisis_active_restaurants, post_active_restaurants,

    -- % of pre retained in crisis and post
    crisis_revenue * 1.0 / NULLIF(pre_revenue, 0) AS crisis_vs_pre_revenue_pct,
    post_revenue   * 1.0 / NULLIF(pre_revenue, 0) AS post_vs_pre_revenue_pct,

    -- recovery from crisis to post
    post_revenue   * 1.0 / NULLIF(crisis_revenue, 0) AS post_vs_crisis_revenue_multiple
FROM p
ORDER BY pre_revenue DESC;


