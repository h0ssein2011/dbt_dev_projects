with 

source as (

    select * from {{ source('Food_Delivery_proj', 'riders') }}

),

renamed as (

    select
        rider_id,
        city,
        vehicle_type,
        activated_date

    from source

)

select * from renamed