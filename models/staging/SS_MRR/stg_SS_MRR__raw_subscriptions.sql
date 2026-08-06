{{
    config(materialized='table')
    }}
with source as (
 select id,
        customer_id,
        plan_id,
        start_date,
        coalesce(end_date,'2099-12-31'),
        status
 from
 {{ source('SS_MRR_proj', 'raw_subscriptions') }}
)
SELECT *
from source