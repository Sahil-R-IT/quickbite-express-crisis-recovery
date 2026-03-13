use QuiteBit;

select
    mms.phase,
    count(*) as months_in_phase,

    -- totals (impact)
    sum(mms.total_orders) as total_orders,
    sum(mms.total_revenue) as total_revenue,

    -- typical month behavior
    avg(mms.active_customer) as avg_monthly_active_customers,
    avg(mms.active_customer_non_cancel) as avg_monthly_active_non_cancel_customers,

    sum(mms.retention_rate * mms.active_customer) * 1.0 / nullif(sum(mms.active_customer), 0) as retention_rate,
    sum(mms.avg_rating * mms.total_rating) * 1.0 / nullif(sum(mms.total_rating), 0) as avg_rating,
    sum(mms.late_rate * mms.deliveries) * 1.0 / nullif(sum(mms.deliveries), 0) as late_rate,

    sum(mms.avg_actual_time_min * mms.deliveries) * 1.0 / nullif(sum(mms.deliveries), 0) as avg_actual_time_min,
    sum(mms.avg_expected_time_min * mms.deliveries) * 1.0 / nullif(sum(mms.deliveries), 0) as avg_expected_time_min,
    (
      sum(mms.avg_actual_time_min * mms.deliveries) - sum(mms.avg_expected_time_min * mms.deliveries)
    ) * 1.0 / nullif(sum(mms.deliveries), 0) as diff_actual_expected_min,

    sum(mms.total_cancelled_order) * 1.0 / nullif(sum(mms.total_orders), 0) as cancellation_rate,

    avg(mms.active_restaurants) as avg_monthly_active_restaurants,
    avg(mms.avg_sentiment) as avg_monthly_sentiment_score
from monthly_master_summary as mms
group by mms.phase
order by case mms.phase
    when 'Pre-Crisis' then 1
    when 'Crisis' then 2
    when 'Post-Crisis' then 3
    else 99
end;

