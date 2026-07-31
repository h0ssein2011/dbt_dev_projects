with

source as (

    select * from {{ source('LB_tutorial', 'stg_payment_attempts') }}

),

renamed as (

    select
        attempt_id,
        order_id,
        employee_id,
        attempted_at,
        status,
        amount_captured

    from source

)

select * from renamed