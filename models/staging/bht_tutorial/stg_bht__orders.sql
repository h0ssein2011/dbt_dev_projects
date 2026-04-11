with 

source as (

    select * from {{ source('bht_tutorial', 'orders') }}

),

renamed as (

    select
        order_id,
        admin_id,
        user_id,
        created_at as order_created_at

    from source

)

select * 
from renamed