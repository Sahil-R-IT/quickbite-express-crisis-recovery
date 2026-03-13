use quitebit;
go

if object_id('monthly_master_summary', 'u') is not null
    drop table monthly_master_summary;
go

select
    mo.month_start_date,
    mo.phase,

    -- core outcomes
    mo.total_orders,
    mo.total_revenue,
    mo.average_order_value,
    mo.total_cancelled_order,
    mo.total_non_cancelled_order,

    -- customers
    mac.active_customer,
    mac.active_customer_non_cancel,

    -- retention (YOU WERE MISSING THIS)
    rcr.active_customers,
    rcr.returning_customers,
    rcr.retention_rate,

    -- delivery
    dps.deliveries,
    dps.avg_expected_time_min,
    dps.avg_actual_time_min,
    dps.diff_minutes_decimal,
    dps.late_rate,

    -- ratings / trust
    rs.avg_rating,
    rs.total_rating,
    rs.low_rating_rate,
    rs.five_start_rating,
    rs.one_start_rating,
    rs.net_rating,
    rs.avg_sentiment,

    -- cancellations
    cr.cancelled_orders,
    cr.cancellation_rate,
    cr.cancellation_rate_pct,

    -- frequency / value per customer
    mopac.order_per_active_customer,
    rpac.revenue_per_active_customer,

    -- restaurants (FIXED JOIN)
    mar.active_restaurants,
    rchr.churn_rate as restaurant_churn_rate,
    rchr.churned_restaurants,
    rchr.active_restaurants_prev_month

into monthly_master_summary
from monthly_order as mo

left join monthly_active_customer as mac
    on mac.month_start_date = mo.month_start_date
   and mac.phase = mo.phase

left join returning_customer_rate as rcr
    on rcr.month_start_date = mo.month_start_date
   and rcr.phase = mo.phase

left join delivery_performance_summary as dps
    on dps.month_start_date = mo.month_start_date
   and dps.phase = mo.phase

left join rating_summary as rs
    on rs.month_start_date = mo.month_start_date
   and rs.phase = mo.phase

left join cancellation_rate as cr
    on cr.month_start_date = mo.month_start_date
   and cr.phase = mo.phase

left join monthly_ordered_active_customer as mopac
    on mopac.month_start_date = mo.month_start_date
   and mopac.phase = mo.phase

left join revenue_per_active_customer as rpac
    on rpac.month_start_date = mo.month_start_date
   and rpac.phase = mo.phase

left join monthly_active_res as mar
    on mar.month_start_date = mo.month_start_date

left join restaurant_churn_rate as rchr
    on rchr.month_start_date = mo.month_start_date;
go

-- validation
select count(*) as rows_in_master from monthly_master_summary;
select month_start_date, phase, count(*) as rows_per_month
from monthly_master_summary
group by month_start_date, phase
having count(*) > 1;

select * from monthly_master_summary
order by month_start_date, phase;


-- master table for daily

use QuiteBit;
go

drop table if exists daily_summary;

with daily_orders as (
    select
        cast(o.order_timestamp as date) as order_date,
        count(*) as total_orders,
        sum(case when o.is_cancelled='N' then 1 else 0 end) as non_cancel_orders,

        sum(case when o.is_cancelled='N' then o.total_amount else 0 end) as revenue_non_cancel,
        avg(case when o.is_cancelled='N' then cast(o.total_amount as float) end) as aov_non_cancel,

        count(distinct case when o.is_cancelled='N' then o.customer_id end) as active_customers_non_cancel,

        sum(case when o.is_cancelled='Y' then 1 else 0 end) as cancelled_orders,
        cast(sum(case when o.is_cancelled='Y' then 1 else 0 end) as float) / nullif(count(*),0) as cancellation_rate
    from fact_orders o
    group by cast(o.order_timestamp as date)
),
daily_ratings as (
    select
        cast(o.order_timestamp as date) as order_date,          -- anchor ratings to order date
        avg(cast(r.rating as float)) as avg_rating,
        count(*) as rating_count,
        avg(case when r.rating <= 2 then 1.0 else 0.0 end) as low_rating_rate
    from fact_ratings r
    join fact_orders o on o.order_id = r.order_id
    group by cast(o.order_timestamp as date)
),
daily_delivery as (
    select
        cast(o.order_timestamp as date) as order_date,
        avg(cast(dp.expected_delivery_time_mins as float)) as avg_expected_time_min,
        avg(cast(dp.actual_delivery_time_mins as float)) as avg_actual_time_min,
        avg(case when dp.actual_delivery_time_mins > dp.expected_delivery_time_mins then 1.0 else 0.0 end) as late_rate
    from fact_delivery_performance dp
    join fact_orders o on o.order_id = dp.order_id
    where o.is_cancelled='N'
    group by cast(o.order_timestamp as date)
)
select
    d.[date] as [date],
    d.phase,

    isnull(o.total_orders,0) as total_orders,
    isnull(o.non_cancel_orders,0) as non_cancel_orders,
    isnull(o.revenue_non_cancel,0) as revenue_non_cancel,
    o.aov_non_cancel,
    isnull(o.active_customers_non_cancel,0) as active_customers_non_cancel,
    o.cancellation_rate,

    r.avg_rating,
    r.rating_count,
    r.low_rating_rate,

    dd.avg_expected_time_min,
    dd.avg_actual_time_min,
    dd.late_rate
into daily_summary
from dim_date d
left join daily_orders o on d.[date] = o.order_date
left join daily_ratings r on d.[date] = r.order_date
left join daily_delivery dd on d.[date] = dd.order_date;

select * from daily_summary order by [date];