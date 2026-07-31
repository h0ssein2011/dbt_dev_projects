with

source as (

    select * from {{ source('LB_tutorial', 'stg_orders') }}

),

renamed as (

    select
        order_id,
        company_id,
        employee_id,
        created_at,
        order_total

    from source

)

select * from renamed