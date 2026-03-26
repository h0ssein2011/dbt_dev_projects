with 

source as (

    select * from {{ source('raw_data', 'countries') }}

),

renamed as (

    select
        code,
        name,
        region

    from source

)

select * from renamed