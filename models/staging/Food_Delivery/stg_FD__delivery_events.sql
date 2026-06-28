with 

source as (

    select * from {{ source('Food_Delivery_proj', 'delivery_events') }}

),
valid_orders as (
    select order_id 
    from {{ ref('stg_FD__orders') }}
)

deduplicated as (

    select
        event_id,
        order_id,
        rider_id,
        event_type,
        event_timestamp
    from source
    where rider_id is not null
    qualify row_number() over(partition by order_id, event_type order by event_timestamp) = 1

) 
, joined as (
    select d.event_id,
        d.order_id,
        d.rider_id,
        d.event_type,
        d.event_timestamp
    from  deduplicated d
    join valid_orders vo on vo.order_id = d.order_id
)

select * 
from joined