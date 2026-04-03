with 

source as (

    select * from {{ source('raw_data', 'company') }}

),

renamed as (

    select
        admin_id,
        country_code,
        name,
        created_at

    from source

)

select * from renamed