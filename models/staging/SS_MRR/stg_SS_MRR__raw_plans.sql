{{
    config(materialized='table')
    }}
with source as (
 select id,
        name,
        billing_interval,
        price
 from
 {{ source('SS_MRR_proj', 'raw_plans') }}
)
SELECT *
from source