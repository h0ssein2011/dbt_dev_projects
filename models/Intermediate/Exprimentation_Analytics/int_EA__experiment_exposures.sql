{{
    config(materialized='table')
    }}
with allocations as (
select user_id,
    experiment_id,
    variant_name,
    allocated_at
from {{ ref('stg_EA__raw_experiment_allocations') }}
)
, events as (
select event_id,
    user_id,
    session_id,
    event_name,
    timestamp,
    device,
    page_url,
    revenue
from {{ ref('int_EA__user_sessions') }}
)
, exposure_events as (
select user_id,
    session_id as exposure_session_id,
    timestamp as exposure_timestamp

from events
where event_name ='begin_checkout'
)
,joined as (
select a.user_id,
    a.experiment_id,
    a.variant_name,
    a.allocated_at,
    min(e.exposure_session_id) as exposure_session_id,
    min(e.exposure_timestamp) as true_exposure_timestamp
from allocations a
left join exposure_events e on a.user_id = e.user_id
     and   e.exposure_timestamp >= a.allocated_at
group by 1,2,3,4
)
, filtered as (
select user_id || '-' || experiment_id as experiment_user_id,
    user_id,
    experiment_id,
    variant_name,
    allocated_at,
    exposure_session_id,
    true_exposure_timestamp

from joined
where true_exposure_timestamp is not null
)
select *
from filtered





