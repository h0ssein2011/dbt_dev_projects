with

source as (

    select * from {{ source('bht_tutorial', 'countries') }}

),

renamed as (

    select
        code as country_code,
        name as country_name,
        region

    from source

)

select *
from renamed