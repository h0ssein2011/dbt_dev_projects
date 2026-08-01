{{
    config(materialized='table')
    }}
with experiment_exposures as (

select user_id,
    experiment_id,
    variant_name,
    allocated_at,
    event_name,
    true_exposure_timestamp,
    device,
    page_url
from {{ ref('int_EA__experiment_exposures') }}
where true_exposure_timestamp is not null
)
, events as  (
select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url
from {{ ref('int_EA__user_sessions') }}
)
joined as (
select ee.user_id,
    ee.experiment_id,
    ee.variant_name,
    max(case when ev.event_name = 'begin_checkout' then 1 else 0 end) as is_checkout_started,
    max(case when ev.event_name = 'purchase' then 1 else 0 end) as is_purchase_completed
from experiment_exposures ee
join events ev on ee.user_id = ev.user_id and ev.timestamp > ee.true_exposure_timestamp
)
select
* from joined
