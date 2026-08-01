{{
    config(materialized='table')
    }}
with begin_checkout as (
select user_id,
    experiment_id,
    variant_name,
    allocated_at
from {{ ref('stg_EA__raw_experiment_allocations') }}
)
, events as (
select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url
from {{ ref('int_EA__user_sessions') }}
)
joined as (
select bc.user_id,
    bc.experiment_id,
    bc.variant_name,
    bc.allocated_at,
    e.event_name
    e.timestamp as exposure_timestamp,
    e.device,
    e.page_url

from begin_checkout bc
join events e on bc.user_id = e.user_id
where  bc.allocated_at >  e.timestamp
)
,first_exposure as (
select user_id,
       experiment_id,
       min(exposure_timestamp)
from joined
group by 1,2
)
, true_exposures as (
select j.user_id,
    j.experiment_id,
    j.variant_name,
    j.allocated_at,
    j.event_name
    j.exposure_timestamp as true_exposure_timestamp,
    j.device,
    j.page_url
from joined j
join first_exposure fe on j.user_id = fe.user_id and j.experiment_id = fe.experiment_id
)
select *
from true_exposures





