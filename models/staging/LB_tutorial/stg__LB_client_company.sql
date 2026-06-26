with 

source as (

    select * from {{ source('LB_tutorial', 'stg_client_company') }}

),

renamed as (

    select
        company_id,
        country_code,
        company_name,
        account_tier,
        created_at

    from source

)

select * from renamed