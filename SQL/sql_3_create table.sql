use QuiteBit

-- the monthly_order table

drop table monthly_order

select 
	d.month_start_date,
	d.phase,
	count(o.order_id) as total_orders,
	
	SUM(case when o.is_cancelled = 'N' then o.total_amount else 0 end) AS total_revenue,
	avg(case when o.is_cancelled = 'N' then cast (o.total_amount as float) end) As average_order_value,
	
	sum(case when o.is_cancelled = 'Y' then 1 else 0 end) as total_cancelled_order,
	sum(case when o.is_cancelled = 'N' then 1 else 0 end) as total_non_cancelled_order
into monthly_order
from fact_orders as o
inner join dim_date as d
	on d.[date] = CAST(o.order_timestamp as date)
Group By d.month_start_date, d.phase
order By d.month_start_date;

select * from monthly_order;


-- create the monthly_active_customer

drop table monthly_active_customer

select 
	d.month_start_date,
	d.phase,
	count(distinct o.customer_id) as active_customer,
	count(distinct case when o.is_cancelled = 'N' then o.customer_id end) as active_customer_non_cancel
into monthly_active_customer
from fact_orders as o
inner join dim_date as d
	on d.[date] = cast(o.order_timestamp as date)
group by d.month_start_date, d.phase
order by d.month_start_date;

select * from monthly_active_customer;

-- create delivery_performance summary
drop table delivery_performance_summary;
select 
	d.month_start_date,
	d.phase,
	count(*) as deliveries,
	
	avg(cast (dp.expected_delivery_time_mins as float)) as avg_expected_time_min,
	avg(cast (dp.actual_delivery_time_mins as float)) as avg_actual_time_min,
	
	round(avg(cast(dp.actual_delivery_time_mins as float) - cast(dp.expected_delivery_time_mins as float) ), 5) as diff_minutes_decimal,
	avg(case when dp.actual_delivery_time_mins > dp.expected_delivery_time_mins then 1.0 else 0.0 end) as late_rate

into delivery_performance_summary
from fact_orders as o
inner join fact_delivery_performance as dp
	on o.order_id = dp.order_id
inner join dim_date as d
	on d.[date] = cast(o.order_timestamp as date)
where o.is_cancelled = 'N'
group by d.month_start_date , d.phase
order by d.month_start_date;
select * from delivery_performance_summary
order by month_start_date;


-- Create Rating Summmay
drop table rating_summary;
select
	d.month_start_date,
	d.phase,

	avg(r.rating) as avg_rating,
	count(r.rating) as total_rating,

	avg(case when r.rating <= 2 then 1.0 else 0.0 end) as low_rating_rate,
	avg(case when r.rating = 5 then 1.0 else 0.0 end) as five_start_rating,
	avg(case when r.rating = 1 then 1.0 else 0.0 end) as one_start_rating,
	(avg(case when r.rating = 5 then 1.0 else 0.0 end) - avg(case when r.rating = 1 then 1.0 else 0.0 end)) as net_rating,
	avg(cast(r.sentiment_score as float)) as avg_sentiment
into rating_summary
from fact_orders as o
inner join fact_ratings as r
	on o.order_id = r.order_id
inner join dim_date as d
	on d.[date] = cast(o.order_timestamp as date)
group by d.month_start_date, d.phase
order by d.month_start_date;
select * from rating_summary order by month_start_date;


-- restaurant_activity_summary

drop table restaurant_activity_summary;
select 
	d.month_start_date,
	d.phase,
	dr.partner_type, 

	count(distinct o.restaurant_id) as monthly_active_restaurant,
	count(distinct case when dr.is_active = 1 then o.restaurant_id end) as active_restaurant_with_orders,
	count(distinct case when dr.is_active = 0 then o.restaurant_id end) as inactive_restaurant_with_ordes
into restaurant_activity_summary
from fact_orders as o
inner join dim_restaurant as dr
	on o.restaurant_id = dr.restaurant_id
inner join dim_date as d
	on d.[date] = cast(o.order_timestamp as date)
where o.is_cancelled = 'N'
group by d.month_start_date, d.phase, dr.partner_type
order by d.month_start_date;

select * from restaurant_activity_summary
order by month_start_date;


-- Monthly cancellation metrics
drop table if exists cancellation_rate;
select
    d.month_start_date,
    d.phase,
    count(*) as total_orders,
    sum(case when o.is_cancelled = 'Y' then 1 else 0 end) as cancelled_orders,
    cast(sum(case when o.is_cancelled = 'Y' then 1 else 0 end) as float)
        / nullif(count(*), 0) as cancellation_rate,
	 ROUND(
        100.0 * CAST(SUM(CASE WHEN o.is_cancelled = 'Y' THEN 1 ELSE 0 END) AS float)
        / NULLIF(COUNT(*), 0), 3) AS cancellation_rate_pct
into cancellation_rate
from fact_orders as o
inner join dim_date as d
    on d.[date] = cast(o.order_timestamp as date)
group by d.month_start_date, d.phase;
select * from cancellation_rate
order by month_start_date;


-- monthly order per active customer

drop table monthly_ordered_active_customer;
select 
	d.month_start_date,
	d.phase,
	sum( case when o.is_cancelled ='N' then 1 else 0 end) as total_noncancel_order,
	count(distinct case when o.is_cancelled = 'N' then o.customer_id end) as active_customer,
	cast( sum( case when o.is_cancelled ='N' then 1 else 0 end) as float) /
		nullif(count(distinct case when o.is_cancelled = 'N' then o.customer_id end), 0) as order_per_active_customer
into monthly_ordered_active_customer
from fact_orders as o
inner join dim_date as d
	on d.[date] = cast(o.order_timestamp as date)
group by d.month_start_date, d.phase;

select * from monthly_ordered_active_customer
order by month_start_date;

-- Revenue per active customer

drop table revenue_per_active_customer;

select 
	d.month_start_date,
	d.phase,

	count(distinct case when o.is_cancelled = 'N' then o.customer_id end) as active_customer_non_cancel,
	sum(case when o.is_cancelled = 'N' then o.total_amount else 0 end) as total_revenue_non_cancel,
	cast(cast (sum(case when o.is_cancelled = 'N' then o.total_amount else 0 end) as decimal(18,4)) /
	nullif(	count(distinct case when o.is_cancelled = 'N' then o.customer_id end), 0) as decimal (18,4)) as revenue_per_active_customer
into revenue_per_active_customer
from fact_orders as o
inner join dim_date as d
	on d.[date] = cast(o.order_timestamp as date)
group by d.month_start_date, d.phase

select * from revenue_per_active_customer
order by month_start_date;


--  monthly Customer activity

drop table monthly_customer_activity;

select distinct
    d.month_start_date,
    d.phase,
    o.customer_id
into monthly_customer_activity
from fact_orders o
inner join dim_date d
    on d.[date] = cast(o.order_timestamp as date)
where o.is_cancelled = 'N';

select top 10 * from monthly_customer_activity;


-- Returning Customers

drop table returning_customer;

select 
	curr.month_start_date,
	curr.phase,
	count(distinct curr.customer_id) as returning_customers
into returning_customer
from monthly_customer_activity as curr
inner join monthly_customer_activity as prev
	on curr.customer_id = prev.customer_id
	and prev.month_start_date = dateadd(month, -1, curr.month_start_date)
group by curr.month_start_date, curr.phase;

select * from returning_customer
order by month_start_date;


-- returning customer rate

drop table returning_customer_rate;

select 
	mac.month_start_date,
	mac.phase,
	mac.active_customer_non_cancel as active_customers,
	isnull(rc.returning_customers, 0) as returning_customers,
	cast(isnull(rc.returning_customers, 0) as float) / nullif(mac.active_customer_non_cancel, 0) as retention_rate
into returning_customer_rate
from monthly_active_customer as mac
left join returning_customer as rc
	on rc.month_start_date = mac.month_start_date
	and rc.phase = mac.phase;

select * from returning_customer_rate
order by month_start_date;


-- monthly restaurant activity

drop table if exists monthly_rest_activity;

select
    d.month_start_date,
    d.phase,
    o.restaurant_id as non_cancel_rest_id
into monthly_rest_activity
from fact_orders o
join dim_date d
  on d.[date] = cast(o.order_timestamp as date)
where o.is_cancelled = 'N'
group by d.month_start_date, d.phase, o.restaurant_id;

select * from monthly_rest_activity
order by month_start_date, phase;

--active restaurants per month

drop table if exists dbo.monthly_active_res;

select
    d.month_start_date,
    d.phase,
    count(distinct o.restaurant_id) as active_restaurants
into dbo.monthly_active_res
from fact_orders o
join dim_date d
  on d.[date] = cast(o.order_timestamp as date)
where o.is_cancelled='N'
group by d.month_start_date, d.phase;

select * from dbo.monthly_active_res
order by month_start_date, phase;

-- churned restaurant per month
drop table if exists churn_restaurants;

select 
    dateadd(month, 1, prev.month_start_date) as month_start_date,
    prev.phase,
    count(distinct prev.non_cancel_rest_id) as churned_restaurants
into churn_restaurants
from monthly_rest_activity prev
left join monthly_rest_activity curr
    on prev.non_cancel_rest_id = curr.non_cancel_rest_id
   and curr.month_start_date = dateadd(month, 1, prev.month_start_date)
   and curr.phase = prev.phase
where curr.non_cancel_rest_id is null
group by dateadd(month, 1, prev.month_start_date), prev.phase;

select * from churn_restaurants
order by month_start_date;

-- churn rate
drop table if exists restaurant_churn_rate;

select
    cr.month_start_date,
    cr.phase,
    cr.churned_restaurants,
    prev.active_restaurants as active_restaurants_prev_month,
    cast(cr.churned_restaurants as float) / nullif(prev.active_restaurants, 0) as churn_rate
into restaurant_churn_rate
from churn_restaurants cr
left join monthly_active_res prev
  on prev.month_start_date = dateadd(month, -1, cr.month_start_date)
 and prev.phase = cr.phase;

select * from restaurant_churn_rate
order by month_start_date;

-- no duplicates per month+phase
select month_start_date, phase, count(*) as cnt
from dbo.restaurant_churn_rate
group by month_start_date, phase
having count(*) > 1;

-- column name
SELECT COLUMN_NAME
FROM QuiteBit.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'monthly_master_summary';