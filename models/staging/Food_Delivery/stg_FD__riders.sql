with 

source as (

    select * from {{ source('Food_Delivery_proj', 'riders') }}

),

deduplicated as (

    select
        rider_id,
        city,
        vehicle_type,
        activated_date

    from source
    where rider_id is not null 
    qualify row_number() over (partition by rider_id order by activated_date desc ) = 1 
    

)

select * from deduplicated
where rider_id is not null 