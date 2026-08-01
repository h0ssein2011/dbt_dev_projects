{{
    config(materialized='table')
    }}
with source as (
 select user_id,
    experiment_id,
    variant_name,
    allocated_at
 from
 {{ source('Exprimentation_Analytics_proj', 'raw_experiment_allocations') }}
)
select *
from source
