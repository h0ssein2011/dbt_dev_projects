with 

source as (

    select * from {{ source('raw_data', 'company_audit_log') }}

),

renamed as (

    select
        id,
        admin_id,
        created_at,
        field,
        old_value,
        new_value,
        changed_by
    from source

)

select * from renamed