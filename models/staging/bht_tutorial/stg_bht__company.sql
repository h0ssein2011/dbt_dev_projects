with

source as (

    select * from {{ source('bht_tutorial', 'company') }}

),

renamed as (

    select
        admin_id,
        country_code,
        name as company_name,
        created_at

    from source

)

select *
from renamed