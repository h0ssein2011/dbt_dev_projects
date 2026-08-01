{{
    config(materialized='table')
    }}
with source as (
 select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url,
    lag(timestamp) over(PARTITION by user_id , device order by timestamp) as prev_session
    lag(event_id) over(PARTITION by user_id , device order by timestamp) as prev_event_id
 from
 {{ ref('stg_EA__raw_events') }}
)
, new_events as (
select case when timestamp_diff(prev_session , timestamp , minute) <= 30 then prev_event_id else event_id end as event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url

from source
)
, deduplicate as (
select event_id,
    user_id,
    event_name,
    timestamp,
    device,
    page_url
from new_events
qualify row_number() over(PARTITION by user_id ,event_id  order by timestamp) = 1
)
select
 *
 FROM deduplicate
