with 

source as (

    select * from {{ source('raw_data', 'users') }}

),

renamed as (

    select
        user_id,
        admin_id,
        full_name,
        created_at,
        country_code

    from source

)

select * from renamed