with

source as (

    select * from {{ source('bht_tutorial', 'orders_try') }}

),

renamed as (

    select order_try_id,
        order_id,
        user_id,
        created_at as order_try_created_at,
        revenue,
        state as order_try_status
    from source

)

select *
from renamed