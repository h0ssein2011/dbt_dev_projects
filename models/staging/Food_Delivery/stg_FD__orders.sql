with 

source as (

    select * from {{ source('Food_Delivery_proj', 'orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_placed_at,
        is_batched
    from source

)

select * 
from renamed