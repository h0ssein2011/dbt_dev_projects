--stg_geography.sql
with

source as (

    select * from {{ source('LB_tutorial', 'stg_geography') }}

),

renamed as (

    select
        country_code,
        country_name,
        region

    from source

)

select * from renamed