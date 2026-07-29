{{
    config(materialized='table')
    }}
with source as (
    select *
    from {{ ref('stg_FD_dev__delivery_events') }}
)
, pivoted as (

SELECT order_id
    , max(rider_id) as rider_id
    , max(case when event_type = 'pickup' then 'event_timestamp' end) as pickup_time
    , max(case when event_type = 'dropoff' then 'event_timestamp' end) as dropoff_time
from source
GROUP by 1

)
,duration_calculated as (

SELECT order_id
    , rider_id
    , pickup_time
    , dropoff_time
    , timestamp_diff(pickup_time , dropoff_time , minute) as delivery_duration_minutes
FROM pivoted
)
, valid_durations as (
SELECT order_id
    , rider_id
    , pickup_time
    , dropoff_time
    , delivery_duration_minutes
from duration_calculated
where pickup_time is not NULL
and dropoff_time is not NULL
and dropoff_time >= pickup_time -- to handle edge cases including delivery and order at the same time!
)
SELECT
from valid_durations

