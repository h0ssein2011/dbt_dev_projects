/*
fct_delivery_performance.sql:
Design: A wide, highly denormalized transactional fact table.
How it's served: It takes the core duration metrics from int_order_delivery_times
and joins them with dimension data from stg_orders (like customer_id, is_batched) and stg_riders (like city, vehicle_type).
It also introduces a business rule column (is_severe_delay if the delivery takes > 45 minutes).
*/

{{
    config(materialized='table')
    }}
with source as (
select order_id
    , rider_id
    , pickup_time
    , dropoff_time
    , delivery_duration_minutes
from {{ ref('int_FD_dev__order_delivery_times') }}
)
, orders as (
select  order_id,
        customer_id,
        order_placed_at,
        is_batched

from {{ ref('stg_FD_dev__orders') }}
)
, riders as (
select  rider_id,
        city,
        vehicle_type,
        activated_date
from {{ ref('stg_FD_dev__riders') }}
)
, joined as (
select s.order_id
    o.customer_id,
    o.is_batched,
    s.rider_id,
    r.city,
    r.vehicle_type,
    s.pickup_time,
    s.dropoff_time,
    s.delivery_duration_minutes,
    case when s.delivery_duration_minutes > 45 then 1 else 0 end as is_severe_delay

FROM source s
join orders o on s.order_id = o.order_id
left join riders r on s.rider_id = r.rider_id
)
select *
from joined