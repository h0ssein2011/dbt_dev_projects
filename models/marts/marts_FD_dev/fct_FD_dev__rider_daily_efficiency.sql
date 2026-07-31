/*
fct_rider_daily_efficiency.sql:
Design: A daily aggregated fact table (snapshot).
How it's served: It takes the complex sequential logic from int_rider_activity_sequences and aggregates it.
 It groups by rider_id and the date (cast(pickup_time as date)) to provide daily roll-up metrics:
 total_orders_delivered, total_active_transit_minutes and total_idle_minutes.
*/

{{
    config(materialized='table')
    }}
with source as (
select order_id,
    rider_id,
    pickup_time,
    dropoff_time,
    previous_dropoff_time,
    delivery_duration_minutes,
    idle_time
from {{ ref('int_FD_dev__rider_activity_sequences') }}
)
, grouped as (
select rider_id,
    cast(pickup_time as date) as reporting_date,
    count(order_id) as total_orders_delivered,
    sum(delivery_duration_minutes) as total_active_transit_minutes,
    sum(idle_time) as total_idle_minutes

from source
group by 1 ,2
)
select *
from grouped