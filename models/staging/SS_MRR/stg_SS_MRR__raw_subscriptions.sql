{{
    config(materialized='table')
    }}
with source as (
 select id,
        customer_id,
        plan_id,
        start_date,
        end_date,
        status
 from
 {{ source('SS_MRR_proj', 'raw_subscriptions') }}
)
SELECT *
from source