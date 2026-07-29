{{
    config(materialized='table')
    }}
with source as (
 select * from {{ source('Food_Delivery_proj', 'delivery_events') }}
)
, valid_orders as (
SELECT order_id
FROM {{ ref('stg_FD__orders') }}
)
,deduplicated as (
SELECT
        event_id,
        order_id,
        rider_id,
        event_type,
        event_timestamp
FROM source
where rider_id is not null
qualify row_number() OVER(PARTITION BY order_id, event_type ORDER BY event_timestamp ) =1
)
, joined as (
SELECT d.event_id,
        d.order_id,
        d.rider_id,
        d.event_type,
        d.event_timestamp

FROM deduplicated d
JOIN valid_orders vo on d.order_id = vo.order_id
)
SELECT *
from joined
