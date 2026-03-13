use QuiteBit

select count(*) from fact_order_items
where order_id is null;

select count(*) from fact_delivery_performance
where order_id is null;

select count(*) from fact_orders
where order_id is null;

select count(*) from fact_ratings
where order_id is null;

SELECT *
INTO clean_fact_ratings
FROM fact_ratings
WHERE NOT (
    order_id IS NULL
    AND rating IS NULL
    AND review_timestamp IS NULL
    AND customer_id IS NULL
);

select count(*) from clean_fact_ratings
where order_id is null;

--change the datatype

Alter table fact_orders alter column total_amount decimal(18,4);
Alter table fact_orders alter column subtotal_amount decimal(18, 4);
Alter table fact_orders alter column delivery_fee decimal(18, 4);
Alter table fact_orders alter column discount_amount decimal(18, 4);
