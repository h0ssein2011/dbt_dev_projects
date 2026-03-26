with 

source as (

    select * from {{ source('raw_data', 'orders') }}

),

renamed as (

    select
        order_id,
        admin_id,
        user_id,
        created_at

    from source

)

select * from renamed