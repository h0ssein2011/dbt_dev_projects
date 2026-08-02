{{
    config(materialized='table')
    }}
with exposures as (

select experiment_user_id,
    user_id,
    experiment_id,
    variant_name,
    allocated_at,
    exposure_session_id,
    true_exposure_timestamp

from {{ ref('int_EA__experiment_exposures') }}
where true_exposure_timestamp is not null
)
, events as  (
select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url,
    coalesce(revenue,0) as revenue
from {{ ref('int_EA__user_sessions') }}
)
,joined as (
select ex.experiment_user_id,
    ex.user_id,
    ex.experiment_id,
    ex.variant_name,
    ex.allocated_at,
    ex.exposure_session_id,
    ex.true_exposure_timestamp,
    e.session_id,
    e.event_name,
    revenue
from exposures ex
join events ev on ex.user_id = ev.user_id and ev.timestamp > ex.true_exposure_timestamp

)
,aggregated as (
select experiment_user_id,
    user_id,
    experiment_id,
    variant_name,
    allocated_at,
    exposure_session_id,
    true_exposure_timestamp,
    max(case when event_name = 'begin_checkout' then 1 else 0 end) > 0 as is_checkout_started,
    max(case when event_name = 'purchase' then 1 else 0 end) > 0 as is_purchase_completed,
    count(distinct session_id) as post_exposure_sessions,
    sum(case when event_name = 'purchase' then revenue else 0 end) as total_revenue
from joined
group by 1,2,3,4,5,6,7)


select *
from aggregated
