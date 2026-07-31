{{
    config(materialized='table')
    }}
with delivery_time as (

    select * from {{ ref('int_FD__orders') }}
)
,sequenced as (
    select
        rider_id,
        order_id,
        pickup_time,
        dropoff_time,
        duration_in_minutes as active_transit_time_minutes,
        lag(dropoff_time) over (partition by rider_id order by pickup_time) as previous_dropoff_time
from delivery_time

),
idle_time_calculated as (
    select
    * , case when previous_dropoff_time is not null and pickup_time > previous_dropoff_time
    then timestamp_diff(pickup_time, previous_dropoff_time, "MINUTE") else 0
    end as idle_time_minutes
    from sequenced

)

select *
from idle_time_calculated

