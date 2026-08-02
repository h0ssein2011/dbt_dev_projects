{{
    config(materialized='table')
    }}
with source as (
 select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url
 from
 {{ ref('stg_EA__raw_events') }}
)
,lagged_events as (
  select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url,
    lag(timestamp) over(partition by user_id order by timestamp) as prev_session
 from source
 )

, session_flags as (
select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url,
    case when timestamp_diff(timestamp , prev_session , minute) > 30 then 1 else 0 end as is_new_session,

from lagged_events
)
, session_indices as (
select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url,
    sum(is_new_session) over(partition by user_id order by timestamp rows between unbounded preceding and current row) as session_index
from session_flags
)
, final as (
select event_id,
    user_id,
    user_id || "-" ||   cast(session_index as string) as session_id,
    event_name,
    timestamp,
    device,
    page_url
 from session_indices
 )
 select
 * from final

