{{
    config(
        materialized='table'
    )
}}
/*
- What is the true average delivery duration (from pickup to dropoff) for batched versus unbatched orders by city? ✅
- Which vehicle type exhibits the highest rate of "severe delays" (defined as a delivery duration exceeding 45 minutes)?
- For each rider calculate their "Active Transit Time" 
    (total time spent between any pickup and dropoff) versus their "Idle Time" (time between completing a dropoff and their next pickup) on this date.✅

*/
with orders as (
select   order_id
        , customer_id
        , order_placed_at
        , is_batched
from {{ ref('stg_FD__orders') }}

),
delivery_events as (
select         event_id
        , order_id
        , rider_id
        , event_type
        , event_timestamp
        , lag(
        if(event_type='pickup'
        ,event_timestamp,null))
        over(partition by rider_id, date(event_timestamp) order by event_timestamp) as last_dropoff_timestamp

    from {{ ref('stg_FD__delivery_events') }}

)
, riders as (
    select rider_id
       , city
        , vehicle_type
        , activated_date
    from {{ ref('stg_FD__riders') }}
)
, delivery_events_by_order as 
(
    select d.order_id
    , d.rider_id
    , min(if(event_type='pickup',event_timestamp,null)) as pickup_timestamp 
    , max(if(event_type='dropoff',event_timestamp,null)) as dropoff_timestamp
    , min(if(event_type='pickup',DATETIME_DIFF(event_timestamp,last_dropoff_timestamp , minute),null)) as idle_duration
from delivery_events d 
join riders r on d.rider_id = r.rider_id

group by 1,2 
) 
, order_details as (
    select d.order_id 
        , o.customer_id
        , d.rider_id
        , r.city
        , r.vehicle_type
        , o.order_placed_at
        , o.is_batched
        , d.idle_duration
        , if(DATETIME_DIFF(d.dropoff_timestamp 
            ,d.pickup_timestamp 
            , minute )>45, 1,0) as had_severe_delay
    from delivery_events_by_order d 
    join orders o on d.order_id = o.order_id
    join riders r on d.rider_id = r.rider_id
)

select *
from order_details
order by 1,2