with 

source as (

    select * from {{ source('raw_data', 'orders_try') }}

),

renamed as (

    select
        order_try_id,
        order_id,
        user_id,
        created_at,
        revenue,
        state

    from source

)

select * from renamed