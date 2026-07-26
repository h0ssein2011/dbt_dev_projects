{{
    config(
        materialized='table'
    )
}}


with orders as (
select  *
from {{ ref('stg_FD__orders') }}

)
, riders as (
    select rider_id
       , city
        , vehicle_type
        , activated_date
    from {{ ref('stg_FD__riders') }}
)
,
delivery_times as (
    select *
    from {{ ref('int_FD__delivery_events') }}
)
, joined as (
    select o.* 
        , r.city
        , r.vehicle_type
        , r.activated_date
        , d.active_transit_time_minutes
        , d.idle_time_minutes
        , d.pickup_time
        , d.dropoff_time
        , if(d.idle_time_minutes>45,1,0) as is_severe_delay
        , if(o.is_batched=1,1,0) as is_batched_order
    from orders o 
    join delivery_times d on o.order_id = d.order_id
    left join riders r on o.rider_id = r.rider_id
)
select *
from joined