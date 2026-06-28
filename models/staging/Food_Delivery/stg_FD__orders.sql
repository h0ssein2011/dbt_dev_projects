with 

source as (

    select * from {{ source('Food_Delivery_proj', 'orders') }}

),

deduplicated as (

    select
        order_id,
        customer_id,
        order_placed_at,
        is_batched
    from source
    where order_id is not null 
    qualify row_number() over (partition by order_id order by order_placed_at desc ) = 1 

)

select * 
from deduplicated