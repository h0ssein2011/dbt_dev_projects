{{
    config(materialized='table')
    }}
with source as (
 select event_id,
    user_id,
    event_name,
    timestamp,
    properties
 from
 {{ source('Exprimentation_Analytics_proj', 'raw_events') }}
)
, unnested as (
select  event_id,
    user_id,
    event_name,
    timestamp,
    JSON_VALUE(properties,'$.device') as device,
    JSON_VALUE(properties,'$.page_url') as page_url,
from source
)
select
*
from unnested
