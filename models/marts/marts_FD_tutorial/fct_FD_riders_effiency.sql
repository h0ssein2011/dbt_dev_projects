{{
    config(
        materialized='table'
    )
}}

with with rider_activity as (
    select * from
    {{ ref('int_FD__delivery_events') }}
)
, daily_aggregated as (
    select 
        rider_id
        , cast(pickup_time as date) as activity_date
        , count(order_id) as total_orders_delivered
        , sum(active_transit_time_minutes) as total_active_transit_minutes
        , sum(idle_time_minutes) as total_idle_minutes
    from rider_activity
    group by 1,2
)
select *
from daily_aggregated