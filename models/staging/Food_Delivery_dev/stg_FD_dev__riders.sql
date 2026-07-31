{{
    config(materialized='table')
    }}
with source as (
 select * from {{ source('Food_Delivery_proj', 'riders') }}
)
, deduplicated as (
select
        rider_id,
        city,
        vehicle_type,
        activated_date
FROM source
where rider_id is not null

qualify row_number() over(PARTITION by rider_id order by activated_date) = 1
)
select *
from deduplicated