{{
    config(materialized='table')
    }}
with 

source as (
    select * 
    from {{ ref('stg_FD__orders') }}
)
, pivoted as (

    select
    order_id,
    max(rider_id) as rider_id,
    max(case when event_type = 'pickup' then event_timestamp end) as pickup_time,
    max(case when event_type = 'dropoff' then event_timestamp end) as dropoff_time

    from  source    
    group by order_id
), duration_calc as (

    select 
    order_id,
    rider_id,
    pickup_time,
    dropoff_time,
    timestamp_diff(dropoff_time, pickup_time, "MINUTE") as duration_in_minutes
from pivoted
)
, valid_durations as (
    select *
    from duration_calc
    where duration_in_minutes > 1
    and pickup_time is not null
    and dropoff_time is not null
    and dropoff_time > pickup_time
)


select * 
from valid_durations


