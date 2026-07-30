/*
int_rider_activity_sequences.sql:
Purpose: Determines rider utilization by calculating idle time between orders.
Logic: It builds on top of int_order_delivery_times.
It uses the LAG() window function partitioned by rider_id to look at a rider's previous drop-off time. It then calculates idle_time_minutes
by measuring the gap between the current order's pickup_time and the previous order's dropoff_time.

*/

{{
    config(materialized='table')
    }}

with source as (
select *
from {{ ref('int_FD_dev__order_delivery_times') }}
)
, lagged as (
SELECT order_id
    , rider_id
    , pickup_time
    , dropoff_time
    , delivery_duration_minutes
    , lag(dropoff_time) over(PARTITION by rider_id order by pickup_time ) as previous_dropoff_time
from source
)
, idle_time_calculated as (
SELECT order_id
    , rider_id
    , pickup_time
    , dropoff_time
    , previous_dropoff_time
    , case when previous_dropoff_time is not null and pickup_time > previous_dropoff_time then
    timestamp_diff( previous_dropoff_time, pickup_time , minute) else 0 end as idle_time
from lagged
)
SELECT *
from idle_time_calculated

