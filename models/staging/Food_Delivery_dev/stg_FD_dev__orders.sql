{{
    config(materialized='table')
    }}
with source as (
 select * from {{ source('Food_Delivery_proj', 'orders') }}
)
, deduplicated as (
SELECT
  order_id,
    customer_id,
    order_placed_at,
    is_batched
FROM source
where order_id is not null

qualify row_number() over(PARTITION by order_id order by order_placed_at DESC) = 1
)
SELECT *
from deduplicated